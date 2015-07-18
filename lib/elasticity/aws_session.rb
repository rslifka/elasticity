module Elasticity

  class MissingKeyError < StandardError;
  end
  class MissingRegionError < StandardError;
  end

  class AwsSession

    attr_reader :access_key
    attr_reader :secret_key
    attr_reader :security_token
    attr_reader :host
    attr_reader :region

    # Supported values for options:
    #  :region - AWS region (e.g. us-west-1)
    #  :secure - true or false, default true.
    def initialize(access=nil, secret=nil, options={})
      # There is a cryptic error if this isn't set
      if options.has_key?(:region) && options[:region] == nil
        raise MissingRegionError, 'A valid :region is required to connect to EMR'
      end
      options[:region] = 'us-east-1' unless options[:region]
      @region = options[:region]

      @access_key = get_access_key(access)
      @secret_key = get_secret_key(secret)
      @security_token = get_security_token
      @host = "elasticmapreduce.#@region.amazonaws.com"
    end

    def submit(ruby_service_hash)
      aws_request = AwsRequestV4.new(self, ruby_service_hash)
      begin
        RestClient.post(aws_request.url, aws_request.payload, aws_request.headers)
      rescue RestClient::BadRequest => e
        raise ArgumentError, AwsSession.parse_error_response(e.http_body)
      end
    end

    def ==(other)
      return false unless other.is_a? AwsSession
      return false unless @access_key == other.access_key
      return false unless @secret_key == other.secret_key
      return false unless @host == other.host
      true
    end

    private

    def get_access_key(access)
      return access if access
      return ENV['AWS_ACCESS_KEY_ID'] if ENV['AWS_ACCESS_KEY_ID']
      raise MissingKeyError, 'Please provide an access key or set AWS_ACCESS_KEY_ID.'
    end

    def get_secret_key(secret)
      return secret if secret
      return ENV['AWS_SECRET_ACCESS_KEY'] if ENV['AWS_SECRET_ACCESS_KEY']
      raise MissingKeyError, 'Please provide a secret key or set AWS_SECRET_ACCESS_KEY.'
    end

    # TODO refactor the entry point to API to incude security_token
    def get_security_token
      ENV['AWS_SECURITY_TOKEN']
    end

    # AWS error responses all follow the same form.  Extract the message from
    # the error document.
    def self.parse_error_response(error_json)
      error = JSON.parse(error_json)
      "AWS EMR API Error (#{error['__type']}): #{error['message']}"
    end

  end

end
