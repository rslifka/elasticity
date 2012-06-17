module Elasticity

  class HadoopBootstrapAction

    attr_accessor :name
    attr_accessor :option
    attr_accessor :value

    def initialize(option, value)
      @name = 'Elasticity Bootstrap Action (Configure Hadoop)'
      @option = option
      @value = value
    end

    def to_aws_bootstrap_action
      {
        :name => @name,
        :script_bootstrap_action => {
          :path => 's3n://elasticmapreduce/bootstrap-actions/configure-hadoop',
          :args => [@option, @value]
        }
      }
    end

  end

end