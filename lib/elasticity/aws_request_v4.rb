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

    def initialize(aws_session, ruby_service_hash)
      @aws_session = aws_session
      @ruby_service_hash = ruby_service_hash
      @timestamp = Time.now.utc
    end

    def headers
      {
        :content_type => 'application/x-www-form-urlencoded; charset=utf-8',
        :Authorization =>
          'AWS4-HMAC-SHA256 ' \
          "Credential=#{@aws_session.access_key}/#{credential_scope}, " \
          'SignedHeaders=content-type;host;x-amz-date, '\
          "Signature=#{aws_v4_signature}",
        'X-Amz-Date' => @timestamp.strftime('%Y%m%dT%H%M%SZ')
      }
    end

    def url
      "https://#{host}"
    end

    def payload
      request_body = AwsUtils.convert_ruby_to_aws(@ruby_service_hash)
      request_body.keys.sort.map do |key|
        "#{AwsUtils.aws_escape(key)}=#{AwsUtils.aws_escape(request_body[key])}"
      end.join('&')
    end

    private

    def host
      "elasticmapreduce.#{@aws_session.region}.amazonaws.com"
    end

    def credential_scope
      "#{@timestamp.strftime('%Y%m%d')}/#{@aws_session.region}/emr/aws4_request"
    end

    # Task 1: Create a Canonical Request For Signature Version 4
    #   http://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
    def canonical_request
      "POST\n" \
      "/\n" \
      "\n" \
      "content-type:application/x-www-form-urlencoded; charset=utf8\n" \
      "host:#{host}\n" \
      "x-amz-date:#{@timestamp.strftime('%Y%m%dT%H%M%SZ')}\n" \
      "\n" \
      "content-type;host;x-amz-date\n" \
      "#{Digest::SHA256.hexdigest(payload)}"
    end

    # Task 2: Create a String to Sign for Signature Version 4
    #   http://docs.aws.amazon.com/general/latest/gr/sigv4-create-string-to-sign.html
    def string_to_sign
      "AWS4-HMAC-SHA256\n" \
      "#{@timestamp.strftime('%Y%m%dT%H%M%SZ')}\n" \
      "#{credential_scope}\n" \
      "#{Digest::SHA256.hexdigest(canonical_request)}"
    end

    # Task 3: Calculate the AWS Signature Version 4
    #   http://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
    def aws_v4_signature
      date = OpenSSL::HMAC.digest('sha256', 'AWS4' + @aws_session.secret_key, @timestamp.strftime('%Y%m%d'))
      region = OpenSSL::HMAC.digest('sha256', date, @aws_session.region)
      service = OpenSSL::HMAC.digest('sha256', region, 'emr')
      signing_key = OpenSSL::HMAC.digest('sha256', service, 'aws4_request')

      OpenSSL::HMAC.hexdigest('sha256', signing_key, string_to_sign)
    end

  end

end