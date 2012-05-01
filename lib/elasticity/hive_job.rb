module Elasticity

  # HiveJob allows you quickly easily kick off a Hive jobflow without
  # having to understand the entirety of the EMR API.
  class HiveJob < Elasticity::SimpleJob

    attr_accessor :script
    attr_accessor :variables

    def initialize(aws_access_key_id, aws_secret_access_key, script)
      super(aws_access_key_id, aws_secret_access_key)
      @name = "Elasticity Hive Job"
      @script = script
      @variables = {}
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
    def run
      script_arguments = ["s3://elasticmapreduce/libs/hive/hive-script", "--run-hive-script", "--args"]
      script_arguments.concat(["-f", @script])

      @variables.each do |name, value|
        script_arguments.concat(["-d", "#{name}=#{value}"])
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
              :action_on_failure => @action_on_failure,
              :hadoop_jar_step => {
                :jar => "s3://elasticmapreduce/libs/script-runner/script-runner.jar",
                :args => script_arguments,
              },
              :name => "Run Hive Script"
            }
        ]
      }

      run_job(jobflow_config)
    end

  end

end