module Elasticity

  class SimpleJob

    attr_accessor :action_on_failure
    attr_accessor :aws_access_key_id
    attr_accessor :aws_secret_access_key
    attr_accessor :ec2_key_name
    attr_accessor :name
    attr_accessor :hadoop_version
    attr_accessor :instance_count
    attr_accessor :log_uri
    attr_accessor :master_instance_type
    attr_accessor :slave_instance_type

    def initialize(aws_access_key_id, aws_secret_access_key, options = {})
      @action_on_failure = "TERMINATE_JOB_FLOW"
      @aws_access_key_id = aws_access_key_id
      @aws_secret_access_key = aws_secret_access_key
      @ec2_key_name = "default"
      @hadoop_version = "0.20"
      @instance_count = 2
      @master_instance_type = "m1.small"
      @name = "Elasticity Job"
      @slave_instance_type = "m1.small"

      @emr = Elasticity::EMR.new(aws_access_key_id, aws_secret_access_key)
    end

    def add_hadoop_bootstrap_action(option, value)
      @hadoop_actions ||= []
      @hadoop_actions << {
        :name => "Elasticity Bootstrap Action (Configure Hadoop)",
        :script_bootstrap_action => {
          :path => "s3n://elasticmapreduce/bootstrap-actions/configure-hadoop",
          :args => [option, value]
        }
      }
    end

    private

    def get_bootstrap_actions
      return {} unless @hadoop_actions && !@hadoop_actions.empty?
      { :bootstrap_actions => @hadoop_actions }
    end

  end

end
