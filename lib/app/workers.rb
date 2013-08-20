require 'beaneater'
require 'tempfile'

require 'app/models'
require 'ploy'

module App
  class << self
    def beanstalk
      @beanstalk ||= Beaneater::Pool.new(App.config.beanstalk_pool)
    end

    def slug_directory
      Fog::Storage[:aws].directories.get(App.config.slug_bucket_name)
    end
  end

  class BeanstalkWorker
    class << self
      attr_reader :tube_name

      def set_tube(name)
        @tube_name = name.to_s
      end

      def tube
        fail "tube_name missing" unless tube_name
        @tube ||= App.beanstalk.tubes[tube_name]
      end

      def set_model(model)
        @model = model
      end

      def model
        fail "model missing" unless @model
        @model
      end

      def perform_async(model_instance)
        tube.put(model_instance.id)
      end
    end

    def run
      App.beanstalk.jobs.register(self.class.tube_name) do |job|
        process_job(job)
      end
      App.beanstalk.jobs.process!
    end

    def process_job(job)
      model_instance = self.class.model.find(job.body)
      perform model_instance
    end

    def perform(model_instance)
      raise NotImplementedError
    end
  end

  # FIXME: Use the BeanstalkWorker
  class HostDeployWorker
    include App::Models

    def perform(deploy_id, host_id)
      deploy = Deploy.find(deploy_id)
      target = deploy.target
      slug   = deploy.slug

      host = target.get_host(host_id)

      t = Tempfile.new("deploy")
      t.write deploy_template(deploy.id, slug.public_url, target.config)
      t.close

      Lines.log("deploying to", host: host.id, target: target.id, slug: slug.commit_id)

      host.scp(t.path, "deploy.sh")

      Lines.log host.ssh("chmod +x deploy.sh && sudo ./deploy.sh").first
    ensure
      t.unlink rescue nil
    end

    protected

    def deploy_template(deploy_id, slug_url, config)
      Ploy.gen_deploy(deploy_id, slug_url, config)
    end
  end

  class BuildWorker < BeanstalkWorker
    include App::Models

    set_tube :builds
    set_model Build

    def perform(build)
      app = build.application
      build_id = build.id
      commit_id = build.commit_id
      branch = build.branch 

      build.change_state("building")

      build_dir = build.build_dir
      build_dir.mkdir_p
      cache_dir = build.cache_dir
      source_repo = build.source_dir

      fail "Repo not found" unless source_repo.directory?

      unless has_commit source_repo, commit_id
        system("git --git-dir #{source_repo} fetch") || fail("git fetch error")
      end
      fail "Commit #{commit_id} not found" unless has_commit(source_repo, commit_id)

      build_script = build_dir / 'build.sh'

      File.open(build_script, 'w', 0755) do |f|
        f.write Ploy.gen_build(cache_dir, source_repo, commit_id, build_id)
      end

      system("#{build_script} 2>&1 | tee #{build_dir}/build.log") || fail("build script error")

      slug_path = build_dir / "#{build_id}.tar.gz"
      fail "Slug not completed" unless slug_path.exist?

      slug_checksum = File.read("#{slug_path}.md5sum").split(' ', 2).first

      file = App.slug_directory.files.create(
        key: "slugs/#{app.name}/#{build_id}.tar.gz",
        body: File.open(slug_path),
        multipart_chunk_size: 5 * 1024 * 1024,
        content_type: 'application/x-gzip',
        content_md5: slug_checksum,
        acl: "private")

      url = file.service.request_url(
        :bucket_name => file.directory.key,
        :object_name => file.key)

      app.slugs.create!(
        commit_id: commit_id,
        branch: branch,
        url: url,
        checksum: "md5:#{slug_checksum}")

      build.change_state("success")
    rescue => ex
      Lines.log ex
      build.change_state("error")
      raise
    end

    protected

    def has_commit(source_repo, commit_id)
      system "git --git-dir #{source_repo} cat-file -t #{commit_id}"
    end
  end
end

if __FILE__ == $0
  App::BuildWorker.new.run
end
