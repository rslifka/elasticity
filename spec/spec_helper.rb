require 'elasticity'
require 'timecop'
require 'fakefs/spec_helpers'

Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|

  config.before(:each) do
    Elasticity.default_configuration
  end

  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :should
  end

end
