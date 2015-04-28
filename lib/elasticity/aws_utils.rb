module Elasticity

  class AwsUtils

    # Escape a string according to Amazon's rules.
    # See: http://docs.amazonwebservices.com/AmazonSimpleDB/2007-11-07/DeveloperGuide/index.html?REST_RESTAuth.html
    def self.aws_escape(param)
      param.to_s.gsub(/([^a-zA-Z0-9._~-]+)/n) do
        '%' + $1.unpack('H2' * $1.size).join('%').upcase
      end
    end

    # With the advent of v4 signing, we can skip the complex translation from v2
    # and ship the JSON over with nearly the same structure.
    def self.convert_ruby_to_aws_v4(value)
      case value
        when Array
          return value.map{|v| convert_ruby_to_aws_v4(v)}
        when Hash
          result = {}
          value.each do |k,v|
            result[camelize(k.to_s)] = convert_ruby_to_aws_v4(v)
          end
          return result
        else
          return value
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

    def self.camelize(word)
      word.to_s.gsub(/\/(.?)/) { '::' + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
    end

  end

end