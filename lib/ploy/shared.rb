module Ploy
  module Shared
    ROOT = File.expand_path('../../..', __FILE__)

    def data_dir
      File.join(ROOT, 'data/ploy')
    end

    # Returns the files you would want in a `ploy init`-like
    # environment.
    def bootstrap_dir
      File.join(data_dir, 'bootstrap')
    end

    # Generates a deploy script
    #
    # This can then be uploaded and executed on a target server.
    def gen_deploy(deploy_id, slug_url, config)
      erb File.join(data_dir, 'deploy.bash.erb'), binding
    end

    def gen_deploy_local(slug_url, config)
      deploy_id = [Time.now.to_i, File.basename(slug_url.sub(/\?.*/,''), '.tar.gz')].join('-')
      gen_deploy(deploy_id, slug_url, config)
    end

    def gen_build(cache_dir, source_dir, commit_id, build_id)
      erb File.join(data_dir, 'build.bash.erb'), binding
    end

    def gen_vagrantfile(hostname, release_id)
      erb File.join(data_dir, 'Vagrantfile.erb'), binding
    end

    protected

    def erb(file_path, binding)
      require 'erb'
      require 'shellwords'
      template = ERB.new File.read(file_path)
      template.result(binding)
    end

  end
end
