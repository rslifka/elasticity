module Elasticity

  class BootstrapAction

    attr_accessor :name
    attr_accessor :option
    attr_accessor :value
    attr_accessor :script

    def initialize(script, option, value)
      @name = 'Elasticity Bootstrap Action'
      @option = option
      @value = value
      @script = script
    end

    def to_aws_bootstrap_action
      {
        :name => @name,
        :script_bootstrap_action => {
          :path => @script,
          :args => [@option, @value]
        }
      }
    end

  end

end