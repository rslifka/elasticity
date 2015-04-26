module Elasticity

  class AwsRequestV2

    def initialize(aws_session, ruby_service_hash)
      @aws_session = aws_session
      @ruby_service_hash = ruby_service_hash
    end

    def url
      "https://elasticmapreduce.#{@aws_session.region}.amazonaws.com"
    end

    def headers
      {
        :content_type => 'application/x-www-form-urlencoded; charset=utf-8'
      }
    end

    # (Used from RightScale's right_aws gem.)
    # EC2, SQS, SDB and EMR requests must be signed by this guy.
    # See: http://docs.amazonwebservices.com/AmazonSimpleDB/2007-11-07/DeveloperGuide/index.html?REST_RESTAuth.html
    #      http://developer.amazonwebservices.com/connect/entry.jspa?externalID=1928
    def payload
      service_hash = AwsUtils.convert_ruby_to_aws(@ruby_service_hash)
      service_hash.merge!({
          'AWSAccessKeyId' => @aws_session.access_key,
          'Timestamp' => Time.now.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z'),
          'SignatureVersion' => '2',
          'SignatureMethod' => 'HmacSHA256'
        })
      canonical_string = service_hash.keys.sort.map do |key|
        "#{AwsUtils.aws_escape(key)}=#{AwsUtils.aws_escape(service_hash[key])}"
      end.join('&')
      string_to_sign = "POST\n#{@aws_session.host.downcase}\n/\n#{canonical_string}"
      signature = AwsUtils.aws_escape(Base64.encode64(OpenSSL::HMAC.digest('sha256', @aws_session.secret_key, string_to_sign)).strip)
      "#{canonical_string}&Signature=#{signature}"
    end

  end

end