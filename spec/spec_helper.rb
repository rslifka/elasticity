require 'rubygems'
require 'bundler/setup'

require 'vcr'

require 'elasticity'

ENV["RAILS_ENV"] ||= 'test'

$:.unshift File.dirname(__FILE__)

VCR.config do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.stub_with :webmock
end