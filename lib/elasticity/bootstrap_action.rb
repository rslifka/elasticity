module Elasticity

  class BootstrapAction

    attr_accessor :name
    attr_reader   :option
    attr_reader   :value
    attr_accessor :script
    attr_accessor :args

    def initialize(script, option, value)
      @name = 'Elasticity Bootstrap Action'
      @option = option
      @value = value
      @script = script
      @args = [option, value]
    end

    def to_aws_bootstrap_action
      {
        :name => @name,
        :script_bootstrap_action => {
          :path => @script,
          :args => @args
        }
      }
    end

    def option=(option)
      @option = option
      @args[0] = option
      warn '[DEPRECATION] `@option` is deprecated, please use @args instead.'
    end

    def value=(value)
      @value = value
      @args[1] = value
      warn '[DEPRECATION] `@value` is deprecated, please use @args instead.'
    end

  end

end