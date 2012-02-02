if ENV['TRAVIS']
  ENV["AWS_ACCESS_KEY_ID"] ||= "abra"
  ENV["AWS_SECRET_KEY"] ||= "cadabra"
end

if !ENV["AWS_ACCESS_KEY_ID"] || !ENV["AWS_SECRET_KEY"]
  puts "\n\n\e[32m**********************************************************************************************"
  puts "Please set \e[0;1mAWS_ACCESS_KEY_ID\e[32m and \e[0;1mAWS_SECRET_KEY\e[32m in your environment to run the tests."
  puts ""
  puts "These keys can be found on your AWS Account > Security Credentials page, at the following URL:"
  puts ""
  puts "  \e[0;1mhttps://aws-portal.amazon.com/gp/aws/developer/account/index.html?ie=UTF8&action=access-key"
  puts ""
  bourne = !ENV['SHELL'].nil? && ENV['SHELL'] =~ /(bash|ksh|zsh)/
  puts "\e[0mbash, zsh, ksh: #{"\e[35;1mThis is you!\e[0m" if bourne}"
  puts "  export AWS_ACCESS_KEY_ID=01234"
  puts "  export AWS_SECRET_KEY=56789"
  puts ""
  puts "\e[0mcsh, tcsh: #{"\e[35;1mThis is you!\e[0m" unless bourne}"
  puts "  setenv AWS_ACCESS_KEY_ID 01234"
  puts "  setenv AWS_SECRET_KEY 56789"
  puts ""
  puts "\e[32m**********************************************************************************************\n\n\n"
  exit
end

AWS_ACCESS_KEY_ID = ENV["AWS_ACCESS_KEY_ID"]
AWS_SECRET_KEY = ENV["AWS_SECRET_KEY"]

require 'rubygems'
require 'bundler/setup'

require 'vcr'

require 'elasticity'

ENV["RAILS_ENV"] ||= 'test'

$:.unshift File.dirname(__FILE__)

VCR.config do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.stub_with :webmock
end

RSpec.configure do |c|
  c.extend VCR::RSpec::Macros
end