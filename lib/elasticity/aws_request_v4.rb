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

    def url
      "#{@aws_session.protocol}://#{host}"
    end

    private

    def host
      "elasticmapreduce.#{@aws_session.region}.amazonaws.com"
    end

    def raw_payload
      request_body = AwsUtils.convert_ruby_to_aws(@ruby_service_hash)
      request_body.keys.sort.map do |key|
        "#{AwsUtils.aws_escape(key)}=#{AwsUtils.aws_escape(request_body[key])}"
      end.join('&')
    end

    # Task 1: Create a Canonical Request For Signature Version 4
    #   http://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
    def canonical_request
      <<-CANONICAL_REQUEST
POST
/

content-type:application/x-www-form-urlencoded; charset=utf8
host:#{host}

content-type;host
#{Digest::SHA256.hexdigest(raw_payload)}
      CANONICAL_REQUEST
    end

  end

end