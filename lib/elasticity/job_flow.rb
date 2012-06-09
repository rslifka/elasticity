module Elasticity

  class JobFlow

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

    def initialize(access, secret)
      @action_on_failure = "TERMINATE_JOB_FLOW"
      @aws_access_key_id = access
      @aws_secret_access_key = secret
      @ec2_key_name = "default"
      @hadoop_version = "0.20"
      @instance_count = 2
      @master_instance_type = "m1.small"
      @name = "Elasticity Job Flow"
      @slave_instance_type = "m1.small"
    end

  end

end