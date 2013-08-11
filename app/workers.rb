require 'app/models'
require 'beaneater'
require 'sidekiq'
require 'tempfile'

module App
  class << self
    def beanstalk
      @beanstalk ||= Beaneater::Pool.new(App.config.beanstalk_pool)
    end

    def slug_directory
      Fog::Storage[:aws].directories.get(App.config.slug_bucket_name)
    end
  end


  class HostDeployWorker
    include Sidekiq::Worker
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

  class BuildWorker
    include App::Models

    class << self
      attr_reader :tube

      def set_tube(name)
        @tube = App.beanstalk.tubes[name]
      end

      def perform_async(build)
        tube.put(build.id)
      end
    end

    set_tube :builds

    def run
      App.beanstalk.jobs.register(self.class.tube.name) do |job|
        process_job(job)
      end
      Lines.log :processing
      App.beanstalk.jobs.process!
    end

    def process_job(job)
      build = Build.find(job.body)
      perform build
      job.delete
    rescue => ex
      Lines.log ex
      job.bury
    end

    def perform(build)
      app = build.application
      build_id = build.id
      commit_id = build.commit_id
      branch = build.branch 

      build.change_state("building")

      build_root = app.data_dir
      build_dir = build_root / 'builds' / build_id
      build_dir.mkdir_p

      source_repo = build_root / 'source_repo'
      raise "Repo not found" unless source_repo.directory?

      #TODO: don't fetch if we have the commit
      system("git --git-dir #{source_repo} fetch") || raise("git fetch error")

      build_script = build_dir / 'build.sh'

      File.open(build_script, 'w', 0755) do |f|
        f.write Ploy.gen_build(build_dir, source_repo, commit_id, build_id)
      end

      system("#{build_script} 2>&1 | tee #{build_dir}/build.log") || raise("build script error")

      slug_path = build_dir / "#{build_id}.tar.gz"
      fail "Slug not completed" unless slug_path.exist?

      slug_checksum = File.read("#{slug_path}.md5sum").split(' ', 1).first

      App.slug_directory.files.create(
        "slugs/#{app.name}/#{build_id}.tar.gz",
        body: File.open(slug_path),
        multipart_chunk_size: 5 * 1024 * 1024,
        content_type: 'application/x-gzip',
        content_md5: slug_checksum,
      )
      App.slug_directory.upload()

      app.slugs.create!(build_id: build_id, commit_id: commit_id, branch: branch, url: 'TODO', checksum: "md5:#{md5sum}")

      build.change_state("success")
    rescue
      build.change_state("error")
      raise
    end
  end
end

if __FILE__ == $0
  App::BuildWorker.new.run
end
