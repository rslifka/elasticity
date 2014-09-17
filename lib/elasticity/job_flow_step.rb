module Elasticity

  module JobFlowStep

    @@step_klasses = []

    def step_root_class
      self.class
    end

    def to_aws_step(jobflow_step)
      raise RuntimeError, '#to_aws_step is required to be defined on all job flow steps.'
    end

    def requires_installation?
      self.class.requires_installation?
    end

    def aws_installation_steps
      self.class.aws_installation_steps
    end

    def aws_installation_step_name
      self.class.aws_installation_step_name
    end

    module ClassMethods

      def requires_installation?
        false
      end

      def aws_installation_steps
        raise RuntimeError, '.aws_installation_step is required to be defined when a step requires installation (e.g. Pig, Hive).'
      end

      def aws_installation_step_name
        raise RuntimeError, '.aws_installation_step_name is required to be defined when a step requires installation (e.g. Pig, Hive).'
      end

    end

    def self.included(base)
      base.extend(ClassMethods)
      @@step_klasses << base
    end

    def self.steps_requiring_installation
      @@step_klasses.select{|klass| klass.requires_installation?}
    end

  end

end
