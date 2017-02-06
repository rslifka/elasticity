module Elasticity

  class PigStep

    include Elasticity::JobFlowStep

    attr_accessor :name
    attr_accessor :script
    attr_accessor :variables
    attr_accessor :action_on_failure

    def initialize(script)
      @name = "Elasticity Pig Step (#{script})"
      @script = script
      @variables = {}
      @action_on_failure = 'TERMINATE_JOB_FLOW'
    end

    def to_aws_step(job_flow)
      args = %w(s3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/pig/pig-script --run-pig-script --args)
      @variables.keys.sort.each do |name|
        args.concat(['-p', "#{name}=#{@variables[name]}"])
      end
      args.concat(['-p', "E_PARALLELS=#{parallels(job_flow.slave_instance_type, job_flow.instance_count)}"])
      args << @script
      {
        :action_on_failure => @action_on_failure,
        :hadoop_jar_step => {
          :jar => 's3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/script-runner/script-runner.jar',
          :args => args,
        },
        :name => @name
      }
    end

    def self.requires_installation?
      true
    end

    def self.aws_installation_step_name
      'Elasticity - Install Pig'
    end

    def self.aws_installation_steps
      [
        {
          :action_on_failure => 'TERMINATE_JOB_FLOW',
          :hadoop_jar_step => {
            :jar => 's3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/script-runner/script-runner.jar',
            :args => [
              's3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/pig/pig-script',
              '--base-path',
              's3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/pig/',
              '--install-pig'
            ],
          },
          :name => aws_installation_step_name
        }
      ]
    end

    private

    # Calculate a common-sense default value of PARALLELS using the following
    # formula from the Pig Cookbook:
    #
    #   <num machines> * <num reduce slots per machine> * 0.9
    #
    # With the following reducer configuration (from an AWS forum post):
    #
    #   m1.small   1
    #   m1.large   2
    #   m1.xlarge  4
    #   c1.medium  2
    #   c1.xlarge  4
    def parallels(slave_instance_type, instance_count)
      reduce_slots = Hash.new(1)
      reduce_slots['m1.small'] = 1
      reduce_slots['m1.large'] = 2
      reduce_slots['m1.xlarge'] = 4
      reduce_slots['c1.medium'] = 2
      reduce_slots['c1.xlarge'] = 4
      ((instance_count - 1).to_f * reduce_slots[slave_instance_type].to_f * 0.9).ceil
    end

  end

end