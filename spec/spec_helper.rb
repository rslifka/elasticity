AWS_ACCESS_KEY_ID = ENV["AWS_ACCESS_KEY_ID"]
AWS_SECRET_KEY = ENV["AWS_SECRET_KEY"]

require 'rubygems'
require 'bundler/setup'

require 'vcr'

require 'elasticity'

ENV["RAILS_ENV"] ||= 'test'

$:.unshift File.dirname(__FILE__)

uri_regexp_matcher = lambda do |real_request, recorded_request|
  real_request.uri =~ recorded_request.uri
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.default_cassette_options = {
    :match_requests_on => [:method, uri_regexp_matcher]
  }
  c.before_http_request do |_|
    require_aws_credentials unless VCR.current_cassette.record_mode == :none
  end
end

RSpec.configure do |c|
  c.extend VCR::RSpec::Macros
end

def require_aws_credentials
  if !ENV["AWS_ACCESS_KEY_ID"] || !ENV["AWS_SECRET_KEY"]
    puts "\n\e[33m**********************************************************************************************"
    puts "\e[32mIf you want to record new cassettes, you'll need to provide a set of AWS credentials so"
    puts "Elasticity can interact with EMR.  These keys can be found on your AWS Account > Security"
    puts "Credentials page, at the following URL:"
    puts ""
    puts "  \e[0;1mhttps://aws-portal.amazon.com/gp/aws/developer/account/index.html?ie=UTF8&action=access-key"
    puts ""
    bourne = !ENV['SHELL'].nil? && ENV['SHELL'] =~ /(bash|ksh|zsh)/
    if bourne
      puts "\e[32mbash, zsh, ksh:"
      puts "  export AWS_ACCESS_KEY_ID=01234"
      puts "  export AWS_SECRET_KEY=56789"
    else
      puts "\e[32mcsh, tcsh:"
      puts "  setenv AWS_ACCESS_KEY_ID 01234"
      puts "  setenv AWS_SECRET_KEY 56789"
    end
    puts "\e[33m**********************************************************************************************\n"
    exit
  end
end