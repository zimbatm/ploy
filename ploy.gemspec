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

  s.files = %w[README.md bin/ploy] + Dir['data/**/*'] + Dir['lib/**/*.rb']
  s.executable = 'ploy'

  s.add_dependency 'ploy-scripts', '0.1.0'

  s.add_dependency 'excon'
  s.add_dependency 'multi_json'
  s.add_dependency 'thor'
end
