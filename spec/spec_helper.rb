require 'elasticity'
require 'timecop'
require 'fakefs/spec_helpers'

Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|

  config.before(:each) do
    Elasticity.default_configuration
  end

end
