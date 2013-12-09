module Elasticity

  class BootstrapAction

    attr_accessor :name
    attr_accessor :script
    attr_accessor :arguments

    def initialize(script, *bootstrap_arguments)
      @name = 'Elasticity Bootstrap Action'
      @script = script
      @arguments = bootstrap_arguments
    end

    def to_aws_bootstrap_action
      action = {
        :name => @name,
        :script_bootstrap_action => {
          :path => @script
        }
      }
      action[:script_bootstrap_action].merge!(:args => @arguments) unless @arguments.empty?
      action
    end

  end

end
