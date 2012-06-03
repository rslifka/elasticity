module Elasticity

  class HiveJob < Elasticity::SimpleJob

    attr_accessor :script
    attr_accessor :variables

    def initialize(aws_access_key_id, aws_secret_access_key, script)
      super(aws_access_key_id, aws_secret_access_key)
      @name = "Elasticity Hive Job"
      @script = script
      @variables = {}
    end

    def ==(other)
      return false unless super
      return false unless @script == other.script
      return false unless @variables == other.variables
      true
    end

    private

    def jobflow_steps
      script_arguments = ["s3://elasticmapreduce/libs/hive/hive-script", "--run-hive-script", "--args"]
      script_arguments.concat(["-f", @script])
      @variables.each do |name, value|
        script_arguments.concat(["-d", "#{name}=#{value}"])
      end
      [
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
    end

  end

end