module Elasticity

  class HadoopBootstrapAction < BootstrapAction

    def initialize(option, value)
      super('s3n://cxar-ato-team/snowplow-hosted-elasticmapreduce/bootstrap-actions/configure-hadoop', option, value)
      self.name = 'Elasticity Bootstrap Action (Configure Hadoop)'
    end

  end

end