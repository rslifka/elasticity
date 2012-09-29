module Elasticity

  class HiveStep

    include Elasticity::JobFlowStep

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

    def to_aws_step(job_flow)
      args = %w(s3://elasticmapreduce/libs/hive/hive-script --base-path s3://elasticmapreduce/libs/hive/ --run-hive-script --args)
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

    def self.requires_installation?
      true
    end

    def self.aws_installation_step
      {
        :action_on_failure => 'TERMINATE_JOB_FLOW',
        :hadoop_jar_step => {
          :jar => 's3://elasticmapreduce/libs/script-runner/script-runner.jar',
          :args => [
            's3://elasticmapreduce/libs/hive/hive-script',
            '--base-path',
            's3://elasticmapreduce/libs/hive/',
            '--install-hive',
            '--hive-versions',
            'latest'
          ],
        },
        :name => 'Elasticity - Install Hive'
      }
    end

  end

end