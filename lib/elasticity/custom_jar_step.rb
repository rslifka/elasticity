module Elasticity

  class CustomJarStep

    include Elasticity::JobFlowStep

    attr_accessor :name
    attr_accessor :jar
    attr_accessor :arguments
    attr_accessor :action_on_failure

    def initialize(jar)
      @name = 'Elasticity Custom Jar Step'
      @jar = jar
      @arguments = []
      @action_on_failure = 'TERMINATE_JOB_FLOW'
    end

    def to_aws_step(job_flow)
      step = {
        :action_on_failure => @action_on_failure,
        :hadoop_jar_step => {
          :jar => @jar
        },
        :name => @name
      }
      step[:hadoop_jar_step][:args] = @arguments unless @arguments.empty?
      step
    end

  end

end