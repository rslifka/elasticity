module Elasticity

  class CustomJarJob < Elasticity::SimpleJob

    attr_accessor :jar
    attr_accessor :arguments

    def initialize(aws_access_key_id, aws_secret_access_key, jar)
      super(aws_access_key_id, aws_secret_access_key)
      @name = "Elasticity Custom Jar Job"
      @jar = jar
    end

    def run
      jobflow_config = {
        :name => @name,
        :instances => {
          :ec2_key_name => @ec2_key_name,
          :hadoop_version => @hadoop_version,
          :instance_count => @instance_count,
          :master_instance_type => @master_instance_type,
          :slave_instance_type => @slave_instance_type,
        },
        :steps => [
          {
            :action_on_failure => @action_on_failure,
            :hadoop_jar_step => {
              :jar => @jar
            },
            :name => "Execute Custom Jar"
          }
        ]
      }

      jobflow_config[:steps].first[:hadoop_jar_step][:args] = @arguments if @arguments

      run_job(jobflow_config)
    end

  end
  
end