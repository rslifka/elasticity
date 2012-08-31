module Elasticity

  class HadoopBootstrapAction < BootstrapAction

    def initialize(option, value)
      @name = 'Elasticity Bootstrap Action (Configure Hadoop)'
      @option = option
      @value = value
      @script = 's3n://elasticmapreduce/bootstrap-actions/configure-hadoop'
    end

  end

end