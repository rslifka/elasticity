module Elasticity

  class GangliaBootstrapAction < BootstrapAction

    def initialize
      super('s3://cxar-ato-team/snowplow-hosted-elasticmapreduce/bootstrap-actions/install-ganglia')
      self.name = 'Elasticity Bootstrap Action (Install Ganglia)'
    end

  end

end
