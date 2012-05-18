require 'rubygems'
require 'bundler/setup'
require 'vcr'
require 'elasticity'

ENV["RAILS_ENV"] ||= 'test'

Dir[File.join(File.dirname(__FILE__), "support", "**", "*.rb")].each { |f| require f }

RSpec.configure do |c|
  c.extend VCR::RSpec::Macros
end
