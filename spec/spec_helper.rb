require 'audumbla'
require 'audumbla/spec/enrichment'

if ENV['COVERAGE'] == 'yes'
  require 'simplecov'
  SimpleCov.start
end

require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'rspec'
require 'factory_girl'
require 'dpla/map/factories'

RSpec.configure do |config|
  config.color = true
  config.formatter = :progress
  config.mock_with :rspec

  config.include FactoryGirl::Syntax::Methods

  config.order = 'random'
end
