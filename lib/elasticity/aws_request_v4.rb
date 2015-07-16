module Elasticity

  # To help ensure correctness, Amazon has provided a step-by-step guide of
  # query-and-response conversations for various types of API calls.
  #
  #   http://docs.aws.amazon.com/general/latest/gr/signature-v4-test-suite.html
  #
  # We are working with POSTs only, where the body of the POST contains the
  # service details, so the 'post-x-www-form-urlencoded-parameters' suite is
  # the most applicable.
  class AwsRequestV4

    SERVICE_NAME = 'elasticmapreduce'

    def initialize(aws_session, ruby_service_hash)
      @aws_session = aws_session

      @ruby_service_hash = ruby_service_hash
      @operation = @ruby_service_hash[:operation]
      @ruby_service_hash.delete(:operation)

      @timestamp = Time.now.utc
    end

    def headers
      default_headers = {
        'Authorization' => "AWS4-HMAC-SHA256 Credential=#{@aws_session.access_key}/#{credential_scope}, SignedHeaders=content-type;host;user-agent;x-amz-content-sha256;x-amz-date;x-amz-target, Signature=#{aws_v4_signature}",
        'Content-Type' => 'application/x-amz-json-1.1',
        'Host' => host,
        'User-Agent' => "elasticity/#{Elasticity::VERSION}",
        'X-Amz-Content-SHA256' => Digest::SHA256.hexdigest(payload),
        'X-Amz-Date' => @timestamp.strftime('%Y%m%dT%H%M%SZ'),
        'X-Amz-Target' => "ElasticMapReduce.#{@operation}"
      }
      default_headers.merge!('X-Amz-Security-Token' => @aws_session.security_token) if @aws_session.security_token
      default_headers
    end

    def url
      "https://#{host}"
    end

    def payload
      AwsUtils.convert_ruby_to_aws_v4(@ruby_service_hash).to_json
    end

    private

    def host
      "elasticmapreduce.#{@aws_session.region}.amazonaws.com"
    end

    def credential_scope
      "#{@timestamp.strftime('%Y%m%d')}/#{@aws_session.region}/#{SERVICE_NAME}/aws4_request"
    end

    # Task 1: Create a Canonical Request For Signature Version 4
    #   http://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
    def canonical_request
      [
        'POST',
        '/',
        '',
        'content-type:application/x-amz-json-1.1',
        "host:#{host}",
        "user-agent:elasticity/#{Elasticity::VERSION}",
        "x-amz-content-sha256:#{Digest::SHA256.hexdigest(payload)}",
        "x-amz-date:#{@timestamp.strftime('%Y%m%dT%H%M%SZ')}",
        "x-amz-target:ElasticMapReduce.#{@operation}",
        '',
        'content-type;host;user-agent;x-amz-content-sha256;x-amz-date;x-amz-target',
        Digest::SHA256.hexdigest(payload)
      ].join("\n")
    end

    # Task 2: Create a String to Sign for Signature Version 4
    #   http://docs.aws.amazon.com/general/latest/gr/sigv4-create-string-to-sign.html
    def string_to_sign
      [
        'AWS4-HMAC-SHA256',
        @timestamp.strftime('%Y%m%dT%H%M%SZ'),
        credential_scope,
        Digest::SHA256.hexdigest(canonical_request)
      ].join("\n")
    end

    # Task 3: Calculate the AWS Signature Version 4
    #   http://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
    def aws_v4_signature
      date = OpenSSL::HMAC.digest('sha256', 'AWS4' + @aws_session.secret_key, @timestamp.strftime('%Y%m%d'))
      region = OpenSSL::HMAC.digest('sha256', date, @aws_session.region)
      service = OpenSSL::HMAC.digest('sha256', region, SERVICE_NAME)
      signing_key = OpenSSL::HMAC.digest('sha256', service, 'aws4_request')

      OpenSSL::HMAC.hexdigest('sha256', signing_key, string_to_sign)
    end

  end

end
