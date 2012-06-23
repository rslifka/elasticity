module Elasticity

  class EMR

    attr_reader :aws_request

    def initialize(aws_access_key_id, aws_secret_access_key, options = {})
      @aws_request = Elasticity::AwsRequest.new(aws_access_key_id, aws_secret_access_key, options)
    end

    # Describe a specific jobflow.
    #
    #   describe_jobflow("j-3UN6WX5RRO2AG")
    #
    # Raises ArgumentError if the specified jobflow does not exist.
    def describe_jobflow(jobflow_id)
      begin
        aws_result = @aws_request.submit(EMR.convert_ruby_to_aws({
          :operation => "DescribeJobFlows",
          :job_flow_ids => [jobflow_id]
        }))
        xml_doc = Nokogiri::XML(aws_result)
        xml_doc.remove_namespaces!
        yield aws_result if block_given?
        JobFlowStatus.from_members_nodeset(xml_doc.xpath("/DescribeJobFlowsResponse/DescribeJobFlowsResult/JobFlows/member")).first
      rescue RestClient::BadRequest => e
        raise ArgumentError, EMR.parse_error_response(e.http_body)
      end
    end

    # Lists all jobflows in all states.
    #
    # To override this behaviour, pass additional filters as specified in the AWS
    # documentation - http://docs.amazonwebservices.com/ElasticMapReduce/latest/API/index.html?API_DescribeJobFlows.html.
    #
    #   describe_jobflows(:CreatedBefore => "2011-10-04")
    def describe_jobflows(params = {})
      aws_result = @aws_request.submit(EMR.convert_ruby_to_aws(
        params.merge({:operation => "DescribeJobFlows"}))
      )
      xml_doc = Nokogiri::XML(aws_result)
      xml_doc.remove_namespaces!
      yield aws_result if block_given?
      JobFlowStatus.from_members_nodeset(xml_doc.xpath("/DescribeJobFlowsResponse/DescribeJobFlowsResult/JobFlows/member"))
    end

    # Adds a new group of instances to the specified jobflow.  Elasticity maps a
    # more Ruby-like syntax to the Amazon options.  An exhaustive hash follows although
    # not all of these options are required (or valid!) at once.  Please see the
    # EMR docs for details although even then you're going to need to experiment :)
    #
    #   instance_group_config = {
    #     :bid_price => 5,
    #     :instance_count => 1,
    #     :instance_role => "TASK",
    #     :market => "SPOT",
    #     :name => "Go Canucks Go!"
    #     :type => "m1.small",
    #   }
    #
    # add_instance_groups takes an array of {}.  Returns an array of the instance IDs
    # that were created by the specified configs.
    #
    #   ["ig-2GOVEN6HVJZID", "ig-1DU9M2UQMM051", "ig-3DZRW4Y2X4S", ...]
    def add_instance_groups(jobflow_id, instance_group_configs)
      params = {
        :operation => "AddInstanceGroups",
        :job_flow_id => jobflow_id,
        :instance_groups => instance_group_configs
      }
      begin
        aws_result = @aws_request.submit(EMR.convert_ruby_to_aws(params))
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

    # Add a step (or steps) to the specified job flow.
    #
    #   emr.add_jobflow_step("j-123", {
    #     :steps => [
    #       {
    #         :action_on_failure => "TERMINATE_JOB_FLOW",
    #         :hadoop_jar_step => {
    #           :args => [
    #             "s3://elasticmapreduce/libs/pig/pig-script",
    #               "--base-path",
    #               "s3://elasticmapreduce/libs/pig/",
    #               "--install-pig"
    #           ],
    #           :jar => "s3://elasticmapreduce/libs/script-runner/script-runner.jar"
    #         },
    #         :name => "Setup Pig"
    #       }
    #     ]
    #   })
    def add_jobflow_steps(jobflow_id, steps_config)
      params = {
        :operation => "AddJobFlowSteps",
        :job_flow_id => jobflow_id
      }.merge!(steps_config)
      begin
        aws_result = @aws_request.submit(EMR.convert_ruby_to_aws(params))
        yield aws_result if block_given?
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
    #   {"ig-1" => 40, "ig-2" => 5, ...}
    def modify_instance_groups(instance_group_config)
      params = {
        :operation => "ModifyInstanceGroups",
        :instance_groups => instance_group_config.map { |k, v| {:instance_group_id => k, :instance_count => v} }
      }
      begin
        aws_result = @aws_request.submit(EMR.convert_ruby_to_aws(params))
        yield aws_result if block_given?
      rescue RestClient::BadRequest => e
        raise ArgumentError, EMR.parse_error_response(e.http_body)
      end
    end

    # Start a job flow with the specified configuration.  This is a very thin
    # wrapper around the AWS API, so in order to use it directly you'll need
    # to have the PDF API reference handy, which can be found here:
    #
    # http://awsdocs.s3.amazonaws.com/ElasticMapReduce/20090331/emr-api-20090331.pdf
    #
    # Here is a sample job flow configuration that should help.  This job flow
    # starts by installing Pig then running a Pig script.  It is based off of the
    # Pig demo script from Amazon.
    #
    #   emr.run_job_flow({
    #     :name => "Elasticity Test Flow (EMR Pig Script)",
    #     :instances => {
    #       :ec2_key_name => "sharethrough-dev",
    #       :hadoop_version => "0.20",
    #       :instance_count => 2,
    #       :master_instance_type => "m1.small",
    #       :placement => {
    #         :availability_zone => "us-east-1a"
    #       },
    #       :slave_instance_type => "m1.small",
    #     },
    #     :steps => [
    #       {
    #         :action_on_failure => "TERMINATE_JOB_FLOW",
    #         :hadoop_jar_step => {
    #           :args => [
    #             "s3://elasticmapreduce/libs/pig/pig-script",
    #               "--base-path",
    #               "s3://elasticmapreduce/libs/pig/",
    #               "--install-pig"
    #           ],
    #           :jar => "s3://elasticmapreduce/libs/script-runner/script-runner.jar"
    #         },
    #         :name => "Setup Pig"
    #       },
    #         {
    #           :action_on_failure => "TERMINATE_JOB_FLOW",
    #           :hadoop_jar_step => {
    #             :args => [
    #               "s3://elasticmapreduce/libs/pig/pig-script",
    #                 "--run-pig-script",
    #                 "--args",
    #                 "-p",
    #                 "INPUT=s3n://elasticmapreduce/samples/pig-apache/input",
    #                 "-p",
    #                 "OUTPUT=s3n://slif-elasticity/pig-apache/output/2011-04-19",
    #                 "s3n://elasticmapreduce/samples/pig-apache/do-reports.pig"
    #             ],
    #             :jar => "s3://elasticmapreduce/libs/script-runner/script-runner.jar"
    #           },
    #           :name => "Run Pig Script"
    #         }
    #     ]
    #   })
    def run_job_flow(job_flow_config)
      params = {
        :operation => "RunJobFlow",
      }.merge!(job_flow_config)
      begin
        aws_result = @aws_request.submit(EMR.convert_ruby_to_aws(params))
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
    #   ["j-1B4D1XP0C0A35", "j-1YG2MYL0HVYS5", ...]
    def set_termination_protection(jobflow_ids, protection_enabled=true)
      params = {
        :operation => "SetTerminationProtection",
        :termination_protected => protection_enabled,
        :job_flow_ids => jobflow_ids
      }
      begin
        aws_result = @aws_request.submit(EMR.convert_ruby_to_aws(params))
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
        aws_result = @aws_request.submit(EMR.convert_ruby_to_aws(params))
        yield aws_result if block_given?
      rescue RestClient::BadRequest
        raise ArgumentError, "Job flow '#{jobflow_id}' does not exist."
      end
    end

    # Pass the specified params hash directly through to the AWS request URL.
    # Use this if you want to perform an operation that hasn't yet been wrapped
    # by Elasticity or you just want to see the response XML for yourself :)
    def direct(params)
      @aws_request.submit(params)
    end

    def ==(other)
      return false unless other.is_a? EMR
      return false unless @aws_request == other.aws_request
      true
    end

    # AWS error responses all follow the same form.  Extract the message from
    # the error document.
    def self.parse_error_response(error_xml)
      xml_doc = Nokogiri::XML(error_xml)
      xml_doc.remove_namespaces!
      xml_doc.xpath("/ErrorResponse/Error/Message").text
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

  end

end
