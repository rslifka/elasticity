module Elasticity

  class AwsRequestV2

    def initialize(aws_session, ruby_service_hash)
      @aws_session = aws_session
      @ruby_service_hash = ruby_service_hash
    end

    def url
      "#{@aws_session.protocol}://elasticmapreduce.#{@aws_session.region}.amazonaws.com"
    end

    def headers
      {
        :content_type => 'application/x-www-form-urlencoded; charset=utf-8'
      }
    end

    def payload
      payload_v2(@ruby_service_hash)
    end

    private

    # (Used from RightScale's right_aws gem.)
    # EC2, SQS, SDB and EMR requests must be signed by this guy.
    # See: http://docs.amazonwebservices.com/AmazonSimpleDB/2007-11-07/DeveloperGuide/index.html?REST_RESTAuth.html
    #      http://developer.amazonwebservices.com/connect/entry.jspa?externalID=1928
    def payload_v2(service_hash)
      service_hash = AwsRequestV2.convert_ruby_to_aws(service_hash)
      service_hash.merge!({
          'AWSAccessKeyId' => @aws_session.access_key,
          'Timestamp' => Time.now.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z'),
          'SignatureVersion' => '2',
          'SignatureMethod' => 'HmacSHA256'
        })
      canonical_string = service_hash.keys.sort.map do |key|
        "#{AwsRequestV2.aws_escape(key)}=#{AwsRequestV2.aws_escape(service_hash[key])}"
      end.join('&')
      string_to_sign = "POST\n#{@aws_session.host.downcase}\n/\n#{canonical_string}"
      signature = AwsRequestV2.aws_escape(Base64.encode64(OpenSSL::HMAC.digest('sha256', @aws_session.secret_key, string_to_sign)).strip)
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
    def self.camelize(word)
      word.to_s.gsub(/\/(.?)/) { '::' + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
    end

  end

end