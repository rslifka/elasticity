module Elasticity

  class PigJob < Elasticity::SimpleJob

    def initialize(aws_access_key_id, aws_secret_access_key)
      super
      @name = "Elasticity Pig Job"
    end

    # Run the specified Pig script with the specified variables.
    #
    #   pig = Elasticity::PigJob.new("access", "secret")
    #   jobflow_id = pig.run('s3n://slif-pig-test/test.pig', {
    #     'SCRIPTS' => 's3n://slif-pig-test/scripts',
    #     'OUTPUT'  => 's3n://slif-pig-test/output',
    #     'XREFS'   => 's3n://slif-pig-test/xrefs'
    #   })
    #
    # The variables are accessible within your Pig scripts by using the
    # standard ${NAME} syntax.
    def run(pig_script, pig_variables={})
      script_arguments = ["s3://elasticmapreduce/libs/pig/pig-script", "--run-pig-script", "--args"]
      pig_variables.keys.sort.each do |variable_name|
        script_arguments.concat(["-p", "#{variable_name}=#{pig_variables[variable_name]}"])
      end
      script_arguments << pig_script
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
            :action_on_failure => "TERMINATE_JOB_FLOW",
            :hadoop_jar_step => {
              :jar => "s3://elasticmapreduce/libs/script-runner/script-runner.jar",
              :args => [
                "s3://elasticmapreduce/libs/pig/pig-script",
                  "--base-path", "s3://elasticmapreduce/libs/pig/",
                  "--install-pig"
              ],
            },
            :name => "Setup Pig"
          },
            {
              :action_on_failure => @action_on_failure,
              :hadoop_jar_step => {
                :jar => "s3://elasticmapreduce/libs/script-runner/script-runner.jar",
                :args => script_arguments,
              },
              :name => "Run Pig Script"
            }
        ]
      }

      jobflow_config.merge!(:log_uri => @log_uri) if @log_uri

      @emr.run_job_flow(jobflow_config)
    end
    
  end
  
end