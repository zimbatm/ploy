require 'app/models'
require 'sidekiq'
require 'tempfile'

module App
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
    include Sidekiq::Worker
    include App::Models

    def perform(slug_id)
      slug = Slug.find(slug_id)
      slug.update_attribute :state, "building"

      build_root = App.data_dir / :apps / slug.app.name
      build_root.mkdir_p

      build_id = slug.build_id
      build_dir = build_root / :builds / build_id

      source_repo = build_root / 'source_repo'
      raise "Repo not found" unless source_repo.directory?

      #TODO: don't fetch if we have the commit
      system("git --git-dir #{source_repo} fetch") || raise("git fetch error")

      build_data = Ploy.gen_build(build_dir, source_repo, slug.commit_id, build_id)

      build_dir.open('build.sh', 'w') do |f|
        f.write build_data
      end

      build_script = build_dir / 'build.sh'
      build_script.chmod('0755')

      system(build_script) || raise("build script error")

      slug.update_attribute :state, "success"
    rescue
      slug.update_attribute :state, "error"
      raise
    end
  end
end
