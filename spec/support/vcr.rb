# Used in the VCR configuration to override URI matching.
uri_regexp_matcher = lambda do |real_request, recorded_request|
  real_request.uri =~ recorded_request.uri
end

# Used in the VCR configuration to validate the presence of AWS keys
# when recording is enabled.
AWS_ACCESS_KEY_ID = ENV['AWS_ACCESS_KEY_ID'] ||= 'default'
AWS_SECRET_KEY = ENV['AWS_SECRET_KEY'] ||= 'default'

def require_aws_credentials
  if AWS_ACCESS_KEY_ID == 'default' && AWS_SECRET_KEY == 'default'
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

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock

  # Override the URI matcher to use a custom validator
  c.default_cassette_options = {
    :match_requests_on => [:method, uri_regexp_matcher]
  }

  # If recording is about to occur, ensure the presence of AWS keys
  c.before_http_request do |_|
    require_aws_credentials unless VCR.current_cassette.record_mode == :none
  end
end
