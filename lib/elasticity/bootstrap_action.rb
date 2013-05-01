module Elasticity

  class BootstrapAction

    attr_accessor :name
    attr_accessor :script
    attr_accessor :arguments

    def initialize(script, *args)
      @name = 'Elasticity Bootstrap Action'
      @script = script
      @arguments = args
    end

    def to_aws_bootstrap_action
      {
        :name => @name,
        :script_bootstrap_action => {
          :path => @script,
          :args => @arguments
        }
      }
    end

  end

end