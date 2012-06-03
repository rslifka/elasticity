module Elasticity

  class CustomJarJob < Elasticity::SimpleJob

    attr_accessor :jar
    attr_accessor :arguments

    def initialize(aws_access_key_id, aws_secret_access_key, jar)
      super(aws_access_key_id, aws_secret_access_key)
      @name = "Elasticity Custom Jar Job"
      @jar = jar
      @arguments = []
    end

    private

    def jobflow_steps
      steps = [
        {
          :action_on_failure => @action_on_failure,
          :hadoop_jar_step => {
            :jar => @jar
          },
          :name => "Execute Custom Jar"
        }
      ]
      steps.first[:hadoop_jar_step][:args] = @arguments unless @arguments.empty?
      steps
    end

  end

end