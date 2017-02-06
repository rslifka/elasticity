module Elasticity

  class SparkStep

    include Elasticity::JobFlowStep

    attr_accessor :name
    attr_accessor :main_class
    attr_accessor :jar
    attr_accessor :spark_arguments
    attr_accessor :app_arguments
    attr_accessor :action_on_failure

    def initialize(jar, main_class)
      @name = 'Elasticity Spark Step'
      @main_class = main_class
      @jar = jar
      @spark_arguments = {}
      @app_arguments = {}
      @action_on_failure = 'TERMINATE_JOB_FLOW'
    end

    def to_aws_step(_)
      args = %W(spark-submit --class #{@main_class})
      spark_arguments.each do |arg, value|
        args << "--#{arg}" << value
      end
      args.push(@jar)
      app_arguments.each do |arg, value|
        args << "--#{arg}" << value
      end
      {
        :name => @name,
        :action_on_failure => @action_on_failure,
        :hadoop_jar_step => {
          :jar => 'command-runner.jar',
          :args => args
        }
      }
    end

  end

end
