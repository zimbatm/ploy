require File.expand_path('../lib/ploy/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'ploy'
  s.version = Ploy::VERSION
  s.summary = 'Faster than deploy'
  s.description = 'An opinionated tool to deploy to the cloud'

  s.author = 'Jonas Pfenniger'
  s.email = 'jonas@mediacore.com'
  s.homepage = 'https://github.com/mediacore/ploy'
  s.license = 'MIT'

  s.files = %w[README.md bin/ploy lib/ploy.rb] +
    Dir['lib/ploy.rb', 'lib/ploy/**/*.rb'] +
    Dir['data/**/*']

  s.executable = 'ploy'

  s.add_dependency 'excon'
  s.add_dependency 'json'
  s.add_dependency 'thor'
end
