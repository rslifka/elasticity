module Elasticity

  class GangliaBootstrapAction < BootstrapAction

    def initialize
      super('s3://elasticmapreduce/bootstrap-actions/install-ganglia')
      self.name = 'Elasticity Bootstrap Action (Install Ganglia)'
    end

  end

end
