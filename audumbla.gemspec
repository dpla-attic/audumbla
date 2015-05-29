$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "audumbla/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'audumbla'
  s.version     = Audumbla::VERSION
  s.authors     = ['Audrey Altman',
                   'Mark Breedlove',
                   'Tom Johnson',
                   'Mark Matienzo']
  s.email       = ["tech@dp.la"]
  s.homepage    = "http://github.com/dpla/audumbla"
  s.summary     = "A toolkit for enhancement of RDF Metadata"
  s.description = "Metadata enrichment for cultural heritage institutions."
  s.license     = "MIT"

  s.files = Dir["lib/**/*",  "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency 'dpla-map', '~>4.0.0.0.pre.10'

  s.add_development_dependency 'rspec', '~>3.0'
  s.add_development_dependency 'pry', '>= 0.10.0'
end
