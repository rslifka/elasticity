module Elasticity

  class AwsRequest

    attr_reader :access_key
    attr_reader :secret_key
    attr_reader :options
    attr_reader :host
    attr_reader :protocol

    # Supported values for options:
    #  :region - AWS region (e.g. us-west-1)
    #  :secure - true or false, default true.
    def initialize(access, secret, options = {})
      @access_key = access
      @secret_key = secret
      @host = options[:region] ? "elasticmapreduce.#{options[:region]}.amazonaws.com" : 'elasticmapreduce.amazonaws.com'
      @protocol = {:secure => true}.merge(options)[:secure] ? 'https' : 'http'
    end

    def submit(ruby_params)
      aws_params = AwsRequest.convert_ruby_to_aws(ruby_params)
      signed_params = sign_params(aws_params, 'GET')
      signed_request = "#@protocol://#@host?#{signed_params}"
      begin
        RestClient.get signed_request
      rescue RestClient::BadRequest => e
        raise ArgumentError, AwsRequest.parse_error_response(e.http_body)
      end
    end

    def ==(other)
      return false unless other.is_a? AwsRequest
      return false unless @access_key == other.access_key
      return false unless @secret_key == other.secret_key
      return false unless @options == other.options
      true
    end

    private

    # (Used from RightScale's right_aws gem.)
    # EC2, SQS, SDB and EMR requests must be signed by this guy.
    # See: http://docs.amazonwebservices.com/AmazonSimpleDB/2007-11-07/DeveloperGuide/index.html?REST_RESTAuth.html
    #      http://developer.amazonwebservices.com/connect/entry.jspa?externalID=1928
    def sign_params(service_hash, http_verb)
      uri = '/' # TODO: Why are we hard-coding this?
      service_hash["AWSAccessKeyId"] = @access_key
      service_hash["Timestamp"] = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S.000Z")
      service_hash["SignatureVersion"] = "2"
      service_hash["SignatureMethod"] = "HmacSHA256"
      canonical_string = service_hash.keys.sort.map do |key|
        "#{AwsRequest.aws_escape(key)}=#{AwsRequest.aws_escape(service_hash[key])}"
      end.join('&')
      string_to_sign = "#{http_verb.to_s.upcase}\n#{@host.downcase}\n#{uri}\n#{canonical_string}"
      signature = AwsRequest.aws_escape(Base64.encode64(OpenSSL::HMAC.digest("sha256", @secret_key, string_to_sign)).strip)
      "#{canonical_string}&Signature=#{signature}"
    end

    # (Used from RightScale's right_aws gem)
    # Escape a string according to Amazon's rules.
    # See: http://docs.amazonwebservices.com/AmazonSimpleDB/2007-11-07/DeveloperGuide/index.html?REST_RESTAuth.html
    def self.aws_escape(param)
      param.to_s.gsub(/([^a-zA-Z0-9._~-]+)/n) do
        '%' + $1.unpack('H2' * $1.size).join('%').upcase
      end
    end

    # Since we use the same structure as AWS, we can generate AWS param names
    # from the Ruby versions of those names (and the param nesting).
    def self.convert_ruby_to_aws(params)
      result = {}
      params.each do |key, value|
        case value
          when Array
            prefix = "#{camelize(key.to_s)}.member"
            value.each_with_index do |item, index|
              if item.is_a?(String)
                result["#{prefix}.#{index+1}"] = item
              else
                convert_ruby_to_aws(item).each do |nested_key, nested_value|
                  result["#{prefix}.#{index+1}.#{nested_key}"] = nested_value
                end
              end
            end
          when Hash
            prefix = "#{camelize(key.to_s)}"
            convert_ruby_to_aws(value).each do |nested_key, nested_value|
              result["#{prefix}.#{nested_key}"] = nested_value
            end
          else
            result[camelize(key.to_s)] = value
        end
      end
      result
    end

    # (Used from Rails' ActiveSupport)
    def self.camelize(lower_case_and_underscored_word, first_letter_in_uppercase = true)
      if first_letter_in_uppercase
        lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
      else
        lower_case_and_underscored_word.first + camelize(lower_case_and_underscored_word)[1..-1]
      end
    end

    # AWS error responses all follow the same form.  Extract the message from
    # the error document.
    def self.parse_error_response(error_xml)
      xml_doc = Nokogiri::XML(error_xml)
      xml_doc.remove_namespaces!
      xml_doc.xpath("/ErrorResponse/Error/Message").text
    end

  end

end
