module Elasticity

  class HiveStep

    include JobFlowStep

    @@hive_version = "0.7.1"

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

    def hive_version
      @@hive_version
    end

    def hive_version= hive_version
      @@hive_version = hive_version
    end

    def to_aws_step(job_flow)
      args = %w(s3://elasticmapreduce/libs/hive/hive-script --run-hive-script)
      args.concat(['--hive-versions',  @@hive_version])
      args.concat(['--args', '-f', @script])
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
      args = [
        's3://elasticmapreduce/libs/hive/hive-script',
        '--base-path',
        's3://elasticmapreduce/libs/hive/',
        '--install-hive',
      ]
      args.concat(['--hive-versions',  @@hive_version])
      {
        :action_on_failure => 'TERMINATE_JOB_FLOW',
        :hadoop_jar_step => {
          :jar => 's3://elasticmapreduce/libs/script-runner/script-runner.jar',
          :args => args,
        },
        :name => 'Elasticity - Install Hive'
      }
    end

  end

end