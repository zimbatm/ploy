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
end
