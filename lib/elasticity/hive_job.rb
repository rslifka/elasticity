module Elasticity

  # HiveJob allows you quickly easily kick off a Hive jobflow without
  # having to understand the entirety of the EMR API.
  class HiveJob

    attr_accessor :aws_access_key_id
    attr_accessor :aws_secret_access_key
    attr_accessor :ec2_key_name
    attr_accessor :name
    attr_accessor :hadoop_version
    attr_accessor :instance_count
    attr_accessor :master_instance_type
    attr_accessor :slave_instance_type

    def initialize(aws_access_key_id, aws_secret_access_key)
      @aws_access_key_id = aws_access_key_id
      @aws_secret_access_key = aws_secret_access_key
      @ec2_key_name = "default"
      @hadoop_version = "0.20"
      @instance_count = 2
      @master_instance_type = "m1.small"
      @name = "Elasticity Hive Job"
      @slave_instance_type = "m1.small"

      @aws_request = Elasticity::AwsRequest.new(aws_access_key_id, aws_secret_access_key)
    end

    # Run the specified Hive script with the specified variables.
    #
    #   hive = Elasticity::HiveJob.new("access", "secret")
    #   jobflow_id = hive.run('s3n://slif-hive/test.q', {
    #     'SCRIPTS' => 's3n://slif-test/scripts',
    #     'OUTPUT'  => 's3n://slif-test/output',
    #     'XREFS'   => 's3n://slif-test/xrefs'
    #   })
    #
    # The variables are accessible within your Hive scripts by using the
    # standard ${NAME} syntax.  E.g.
    #
    #   ADD JAR ${SCRIPTS}/jsonserde.jar;
    def run(hive_script, hive_variables={})
      script_arguments = ["s3://elasticmapreduce/libs/hive/hive-script", "--run-hive-script", "--args"]
      script_arguments.concat(["-f", hive_script])
      hive_variables.each do |variable_name, value|
        script_arguments.concat(["-d", "#{variable_name}=#{value}"])
      end
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
                "s3://elasticmapreduce/libs/hive/hive-script",
                  "--base-path", "s3://elasticmapreduce/libs/hive/",
                  "--install-hive"
              ],
            },
            :name => "Setup Hive"
          },
            {
              :action_on_failure => "TERMINATE_JOB_FLOW",
              :hadoop_jar_step => {
                :jar => "s3://elasticmapreduce/libs/script-runner/script-runner.jar",
                :args => script_arguments,
              },
              :name => "Run Hive Script"
            }
        ]
      }
      @aws_request.run_job_flow(jobflow_config)
    end

  end

end