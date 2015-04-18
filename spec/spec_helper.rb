require 'krikri'

if ENV['COVERAGE'] == 'yes'
  require 'simplecov'
  SimpleCov.start
end

require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'rspec'
require 'factory_girl'

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.color = true
  config.formatter = :progress
  config.mock_with :rspec

  config.include FactoryGirl::Syntax::Methods

  config.order = 'random'
end
