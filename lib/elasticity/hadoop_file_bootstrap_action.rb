module Elasticity

  class HadoopFileBootstrapAction < BootstrapAction

    def initialize(config_file)
      @name = 'Elasticity Bootstrap Action (Configure Hadoop via File)'
      @option = '--mapred-config-file'
      @value = config_file
      @script = 's3n://elasticmapreduce/bootstrap-actions/configure-hadoop'
    end

  end

end