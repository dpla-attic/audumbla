$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "krikri/enrichments/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "krikri-enrichments"
  s.version     = Krikri::Enrichments::VERSION
  s.authors     = ['Audrey Altman',
                   'Mark Breedlove',
                   'Tom Johnson',
                   'Mark Matienzo']
  s.email       = ["tech@dp.la"]
  s.homepage    = "http://github.com/dpla/krikri-enrichments"
  s.summary     = "A toolkit for enhancement of RDF Metadata"
  s.license     = "MIT"

  s.files = Dir["lib/**/*",  "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency 'dpla-map', '~>4.0.0.0.pre.10'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'pry'
end
