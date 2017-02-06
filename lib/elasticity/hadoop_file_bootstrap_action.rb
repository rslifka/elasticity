module Elasticity

  class HadoopFileBootstrapAction < BootstrapAction

    def initialize(config_file)
      super('s3n://cxar-ato-team/snowplow-hosted-elasticmapreduce/bootstrap-actions/configure-hadoop', '--mapred-config-file', config_file)
      self.name = 'Elasticity Bootstrap Action (Configure Hadoop via File)'
    end

  end

end