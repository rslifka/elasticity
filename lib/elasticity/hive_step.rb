module Elasticity

  class HiveStep

    attr_accessor :name
    attr_accessor :script
    attr_accessor :variables
    attr_accessor :action_on_failure

    def initialize(script)
      @name = "Elasticity Hive Step (#{script})"
      @script = script
      @variables = { }
      @action_on_failure = 'TERMINATE_JOB_FLOW'
    end

    def aws_installation_step
      {
        :action_on_failure => 'TERMINATE_JOB_FLOW',
        :hadoop_jar_step => {
          :jar => 's3://elasticmapreduce/libs/script-runner/script-runner.jar',
          :args => [
            's3://elasticmapreduce/libs/hive/hive-script',
              '--base-path',
              's3://elasticmapreduce/libs/hive/',
              '--install-hive'
          ],
        },
        :name => 'Elasticity - Install Hive'
      }
    end

    def to_aws_step(job_flow)
      args = %w(s3://elasticmapreduce/libs/hive/hive-script --run-hive-script --args)
      args.concat(['-f', @script])
      @variables.keys.sort.each do |name|
        args.concat(['-d', "#{name}=#{@variables[name]}"])
      end
      {
        :name => @name,
        :action_on_failure => @action_on_failure,
        :hadoop_jar_step => {
          :jar => 's3://elasticmapreduce/libs/script-runner/script-runner.jar',
          :args => args
        }
      }
    end

  end

end