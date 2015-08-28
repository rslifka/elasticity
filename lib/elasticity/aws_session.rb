module Elasticity

  class MissingKeyError < StandardError; end
  class MissingRegionError < StandardError; end
  class ThrottlingException < StandardError; end

  class AwsSession

    attr_reader :host
    attr_reader :region

    # Supported values for options:
    #  :region - AWS region (e.g. us-west-1)
    #  :secure - true or false, default true.
    def initialize(options={})
      # There is a cryptic error if this isn't set
      if options.has_key?(:region) && options[:region] == nil
        raise MissingRegionError, 'A valid :region is required to connect to EMR'
      end
      options[:region] = 'us-east-1' unless options[:region]
      @region = options[:region]

      @host = "elasticmapreduce.#@region.amazonaws.com"
    end

    def submit(ruby_service_hash)
      aws_request = AwsRequestV4.new(self, ruby_service_hash)
      begin
        RestClient.post(aws_request.url, aws_request.payload, aws_request.headers)
      rescue RestClient::BadRequest => e
        type, message = AwsSession.parse_error_response(e.http_body)
        raise ThrottlingException, message if type == 'ThrottlingException'
        raise ArgumentError, message
      end
    end

    def ==(other)
      return false unless other.is_a? AwsSession
      return false unless @host == other.host
      true
    end

    private

    # AWS error responses all follow the same form.  Extract the message from
    # the error document.
    def self.parse_error_response(error_json)
      error = JSON.parse(error_json)
      [
        error['__type'],
        "AWS EMR API Error (#{error['__type']}): #{error['message']}"
      ]
    end

  end

end
