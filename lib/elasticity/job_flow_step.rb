module Elasticity

  module JobFlowStep

    def to_aws_step(jobflow_step)
      raise RuntimeError, '#to_aws_step is required to be defined on all job flow steps.'
    end

    def requires_installation?
      self.class.requires_installation?
    end

    def aws_installation_step
      self.class.aws_installation_step
    end

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
