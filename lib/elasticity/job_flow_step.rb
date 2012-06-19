module Elasticity

  module JobFlowStep

    module ClassMethods

      def requires_installation?
        false
      end

      def aws_installation_step
        raise RuntimeError, '.aws_installation_step is required to be defined when a step requires installation (e.g. Pig, Hive).'
      end

    end

    def self.included(base)
      base.extend(ClassMethods)
    end

  end

end
