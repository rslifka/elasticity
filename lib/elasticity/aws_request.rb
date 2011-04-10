module Elasticity

  class AwsRequest

    def initialize(aws_access_key_id, aws_secret_access_key)
      @access_key = aws_access_key_id
      @secret_key = aws_secret_access_key
    end

    def aws_emr_request(params)
      signed_params = sign_params(params, "GET", "elasticmapreduce.amazonaws.com", "/")
      signed_request = "http://elasticmapreduce.amazonaws.com?#{signed_params}"
      RestClient.get signed_request
    end

    # (Used from RightScale's right_aws gem.)
    # EC2, SQS, SDB and EMR requests must be signed by this guy.
    # See: http://docs.amazonwebservices.com/AmazonSimpleDB/2007-11-07/DeveloperGuide/index.html?REST_RESTAuth.html
    #      http://developer.amazonwebservices.com/connect/entry.jspa?externalID=1928
    def sign_params(service_hash, http_verb, host, uri)
      service_hash["AWSAccessKeyId"] = @access_key
      service_hash["Timestamp"] = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S.000Z")
      service_hash["SignatureVersion"] = "2"
      service_hash['SignatureMethod'] = 'HmacSHA256'
      canonical_string = service_hash.keys.sort.map do |key|
        "#{AwsRequest.aws_escape(key)}=#{AwsRequest.aws_escape(service_hash[key])}"
      end.join('&')
      string_to_sign = "#{http_verb.to_s.upcase}\n#{host.downcase}\n#{uri}\n#{canonical_string}"
      signature = AwsRequest.aws_escape(Base64.encode64(OpenSSL::HMAC.digest("sha256", @secret_key, string_to_sign)).strip)
      "#{canonical_string}&Signature=#{signature}"
    end

    class << self

      # (Used from RightScale's right_aws gem)
      # Escape a string according to Amazon's rules.
      # See: http://docs.amazonwebservices.com/AmazonSimpleDB/2007-11-07/DeveloperGuide/index.html?REST_RESTAuth.html
      def aws_escape(param)
        param.to_s.gsub(/([^a-zA-Z0-9._~-]+)/n) do
          '%' + $1.unpack('H2' * $1.size).join('%').upcase
        end
      end

    end

  end

end