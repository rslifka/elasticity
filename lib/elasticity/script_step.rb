module Elasticity

  class ScriptStep < CustomJarStep

    def initialize(region, script_name, *script_args)
      @name = 'Elasticity Script Step'
      @jar = "s3://#{region}.elasticmapreduce/libs/script-runner/script-runner.jar"
      @arguments = [script_name].concat(script_args)
      @action_on_failure = 'TERMINATE_JOB_FLOW'
    end

  end

end
