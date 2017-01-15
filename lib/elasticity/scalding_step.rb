module Elasticity

  class ScaldingStep

    include Elasticity::JobFlowStep

    attr_accessor :name
    attr_accessor :action_on_failure
    attr_accessor :jar
    attr_accessor :arguments

    def initialize(jar, main_class, args)
      @name = 'Elasticity Scalding Step'
      @action_on_failure = 'TERMINATE_JOB_FLOW'
      @jar = jar
      @arguments = [ main_class, '--hdfs' ]
      args.each do |arg, value|
        @arguments << "--#{arg}" << value
      end
    end

    def to_aws_step(job_flow)
      step = Elasticity::CustomJarStep.new(@jar)
      step.name = @name
      step.action_on_failure = @action_on_failure
      step.arguments = @arguments
      step.to_aws_step(job_flow)
    end

  end

end
