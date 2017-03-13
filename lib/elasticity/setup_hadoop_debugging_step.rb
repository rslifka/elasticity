module Elasticity

  class SetupHadoopDebuggingStep < CustomJarStep

    def initialize(region)
      @name = 'Elasticity Setup Hadoop Debugging'
      @jar = "s3://#{region}.elasticmapreduce/libs/script-runner/script-runner.jar"
      @arguments = ["s3://#{region}.elasticmapreduce/libs/state-pusher/0.1/fetch"]
      @action_on_failure = 'TERMINATE_JOB_FLOW'
    end

  end

end
