module Elasticity

  class ScriptStep < CustomJarStep

    def initialize(script_name, *script_args)
      @name = 'Elasticity Script Step'
      @jar = 's3://elasticmapreduce/libs/script-runner/script-runner.jar'
      @arguments = ["#{script_name} #{script_args.join(' ')}"]
    end

  end

end