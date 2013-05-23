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

  class FooWorker
    include Sidekiq::Worker

    def perform(something)
      puts "Doing something #{something}"
    end
  end
end
