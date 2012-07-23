module Elasticity

  class StreamingStep

    include JobFlowStep

    attr_accessor :name
    attr_accessor :action_on_failure
    attr_accessor :input_bucket
    attr_accessor :output_bucket
    attr_accessor :mapper
    attr_accessor :reducer

    def initialize(input_bucket, output_bucket, mapper, reducer)
      @name = 'Elasticity Streaming Step'
      @action_on_failure = 'TERMINATE_JOB_FLOW'
      @input_bucket = input_bucket
      @output_bucket = output_bucket
      @mapper = mapper
      @reducer = reducer
    end

    def to_aws_step(job_flow)
      step = Elasticity::CustomJarStep.new('/home/hadoop/contrib/streaming/hadoop-streaming.jar')
      step.name = @name
      step.action_on_failure = @action_on_failure
      step.arguments = ['-input', @input_bucket, '-output', @output_bucket, '-mapper', @mapper, '-reducer', @reducer]
      step.to_aws_step(job_flow)
    end

  end

end