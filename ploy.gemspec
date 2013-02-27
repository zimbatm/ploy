Gem::Specification.new do |s|
  s.name = 'ploy'
  s.version = '1.0'
  s.summary = 'Faster than deploy'
  s.description = 'An opinionated tool to deploy to the cloud'

  s.author = 'Jonas Pfenniger'
  s.email = 'jonas@mediacore.com'
  s.homepage = 'https://github.com/mediacore/ploy'
  s.license = 'MIT'

  s.files = ['README.md', 'bin/ploy', *Dir['lib/**/*.rb']]
  s.executable = 'ploy'

  s.add_dependency 'ploy-scripts', '0.1.0'
  s.add_dependency 'excon', '~> 0.16.0'
  s.add_dependency 'multi_json', '~> 1.6.0'
  s.add_dependency 'scrolls', '~> 0.2.0'
end
