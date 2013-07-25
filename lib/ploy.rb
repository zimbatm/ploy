module Ploy
  ROOT = File.expand_path('../..', __FILE__)

  def data_dir
    File.join(ROOT, 'data/ploy')
  end

  # Returns the files you would want in a `ploy init`-like
  # environment.
  def bootstrap_dir
    File.join(data_dir, 'bootstrap')
  end

  # Path to build script
  def build_script
    File.join(data_dir, 'build-script')
  end

  # Generates a deploy script
  #
  # This can then be uploaded and executed on a target server.
  def gen_deploy(deploy_id, slug_url, config)
    require 'erb'
    require 'shellwords'
    template = ERB.new(File.read(File.join(data_dir, 'deploy.bash.erb')))
    template.result(binding)
  end

  extend self
end
