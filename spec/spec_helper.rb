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

require 'cgi'

ENV["RAILS_ENV"] ||= 'test'

$:.unshift File.dirname(__FILE__)

def params_to_hash(request)
  uri = URI.parse(request.uri)
  hash = CGI::parse(uri.query)
  ['AWSAccessKeyId', 'Signature', 'SignatureMethod', 'SignatureVersion', 'Timestamp'].each do |param|
    hash[param] = ''
  end
  hash
end

params_matcher = lambda do |request_1, request_2|
  params_to_hash(request_1) == params_to_hash(request_2)
end

VCR.configure do |c|
  c.default_cassette_options[:match_requests_on] = [
      :method,
      :host,
      :path,
      params_matcher
  ]
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
end

RSpec.configure do |c|
  c.extend VCR::RSpec::Macros
end