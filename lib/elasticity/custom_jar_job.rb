module Elasticity

  class CustomJarJob < Elasticity::SimpleJob

    def initialize(aws_access_key_id, aws_secret_access_key)
      super
      @name = "Elasticity Custom Jar Job"
    end

    def run(jar, arguments=nil)
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
              :jar => jar
            },
            :name => "Execute Custom Jar"
          }
        ]
      }
      jobflow_config.merge!(:log_uri => @log_uri) if @log_uri
      jobflow_config[:steps].first[:hadoop_jar_step][:args] = arguments if arguments
      @emr.run_job_flow(jobflow_config)
    end

  end
  
end