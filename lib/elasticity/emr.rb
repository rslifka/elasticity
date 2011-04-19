module Elasticity

  class EMR

    def initialize(aws_access_key_id, aws_secret_access_key)
      @aws_request = Elasticity::AwsRequest.new(aws_access_key_id, aws_secret_access_key)
    end

    # Lists all jobflows in all states.
    def describe_jobflows
      aws_result = @aws_request.aws_emr_request(EMR.convert_ruby_to_aws(:operation => "DescribeJobFlows"))
      xml_doc = Nokogiri::XML(aws_result)
      xml_doc.remove_namespaces!
      yield aws_result if block_given?
      JobFlow.from_members_nodeset(xml_doc.xpath("/DescribeJobFlowsResponse/DescribeJobFlowsResult/JobFlows/member"))
    end

    # Adds a new group of instances to the specified jobflow.  Elasticity maps a
    # more Ruby-like syntax to the Amazon options.  An exhaustive hash follows although
    # not all of these options are required (or valid!) at once.  Please see the
    # EMR docs for details although even then you're going to need to experiment :)
    #
    # instance_group_config = {
    #   :bid_price => 5,
    #   :instance_count => 1,
    #   :instance_role => "TASK",
    #   :market => "SPOT",
    #   :name => "Go Canucks Go!"
    #   :type => "m1.small",
    # }
    #
    # add_instance_groups takes an array of {}.
    #
    # Returns an array of the instance IDs that were created by the specified configs.
    # 
    #  ["ig-2GOVEN6HVJZID", "ig-1DU9M2UQMM051", "ig-3DZRW4Y2X4S", ...]
    def add_instance_groups(jobflow_id, instance_group_configs)
      params = {
        :operation => "AddInstanceGroups",
        :job_flow_id => jobflow_id,
        :instance_groups => instance_group_configs
      }
      begin
        aws_result = @aws_request.aws_emr_request(EMR.convert_ruby_to_aws(params))
        xml_doc = Nokogiri::XML(aws_result)
        xml_doc.remove_namespaces!
        instance_group_ids = []
        xml_doc.xpath("/AddInstanceGroupsResponse/AddInstanceGroupsResult/InstanceGroupIds/member").each do |member|
          instance_group_ids << member.text
        end
        yield aws_result if block_given?
        instance_group_ids
      rescue RestClient::BadRequest => e
        raise ArgumentError, EMR.parse_error_response(e.http_body)
      end
    end

    # Set the number of instances in the specified instance groups to the
    # specified counts.  Note that this modifies the *request* count, which
    # is not the same as the *running* count.  I.e. you request instances
    # and then wait for them to be created.
    #
    # Takes a {} of instance group IDs => desired instance count.
    #
    # {"ig-1" => 40, "ig-2" => 5, ...}
    def modify_instance_groups(instance_group_config)
      params = {
        :operation => "ModifyInstanceGroups",
        :instance_groups => instance_group_config.map { |k, v| {:instance_group_id => k, :instance_count => v} }
      }
      begin
        aws_result = @aws_request.aws_emr_request(EMR.convert_ruby_to_aws(params))
        yield aws_result if block_given?
      rescue RestClient::BadRequest => e
        raise ArgumentError, EMR.parse_error_response(e.http_body)
      end
    end

    # TODO DOCUMENT ME
    def run_job_flow(job_flow_config)
      params = {
        :operation => "RunJobFlow",
      }.merge!(job_flow_config)
      begin
        aws_result = @aws_request.aws_emr_request(EMR.convert_ruby_to_aws(params))
        yield aws_result if block_given?
        xml_doc = Nokogiri::XML(aws_result)
        xml_doc.remove_namespaces!
        xml_doc.xpath("/RunJobFlowResponse/RunJobFlowResult/JobFlowId").text
      rescue RestClient::BadRequest => e
        raise ArgumentError, EMR.parse_error_response(e.http_body)
      end
    end

    # Enabled or disable "termination protection" on the specified job flows.
    # Termination protection prevents a job flow from being terminated by a
    # user initiated action, although the job flow will still terminate
    # naturally.
    #
    # Takes an [] of job flow IDs.
    #
    # ["j-1B4D1XP0C0A35", "j-1YG2MYL0HVYS5", ...]
    def set_termination_protection(jobflow_ids, protection_enabled=true)
      params = {
        :operation => "SetTerminationProtection",
        :termination_protected => protection_enabled,
        :job_flow_ids => jobflow_ids
      }
      begin
        aws_result = @aws_request.aws_emr_request(EMR.convert_ruby_to_aws(params))
        yield aws_result if block_given?
      rescue RestClient::BadRequest => e
        raise ArgumentError, EMR.parse_error_response(e.http_body)
      end
    end

    # Terminate the specified jobflow.  Amazon does not define a return value
    # for this operation, so you'll need to poll #describe_jobflows to see
    # the state of the jobflow.  Raises ArgumentError if the specified job
    # flow does not exist.
    def terminate_jobflows(jobflow_id)
      params = {
        :operation => "TerminateJobFlows",
        :job_flow_ids => [jobflow_id]
      }
      begin
        aws_result = @aws_request.aws_emr_request(EMR.convert_ruby_to_aws(params))
        yield aws_result if block_given?
      rescue RestClient::BadRequest
        raise ArgumentError, "Job flow '#{jobflow_id}' does not exist."
      end
    end

    # Pass the specified params hash directly through to the AWS request URL.
    # Use this if you want to perform an operation that hasn't yet been wrapped
    # by Elasticity or you just want to see the response XML for yourself :)
    def direct(params)
      @aws_request.aws_emr_request(params)
    end

    private

    class << self

      # AWS error responses all follow the same form.  Extract the message from
      # the error document.
      def parse_error_response(error_xml)
        xml_doc = Nokogiri::XML(error_xml)
        xml_doc.remove_namespaces!
        xml_doc.xpath("/ErrorResponse/Error/Message").text
      end

      # Since we use the same structure as AWS, we can generate AWS param names
      # from the Ruby versions of those names (and the param nesting).
      def convert_ruby_to_aws(params)
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
      def camelize(lower_case_and_underscored_word, first_letter_in_uppercase = true)
        if first_letter_in_uppercase
          lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
        else
          lower_case_and_underscored_word.first + camelize(lower_case_and_underscored_word)[1..-1]
        end
      end

    end

  end

end
