module Elasticity

  class CustomJarStep

    include Elasticity::JobFlowStep

    attr_accessor :name
    attr_accessor :jar
    attr_accessor :arguments
    attr_accessor :action_on_failure
    attr_accessor :caches
    attr_accessor :main_class

    def initialize(jar)
      @name = 'Elasticity Custom Jar Step'
      @jar = jar
      @arguments = []
      @action_on_failure = 'TERMINATE_JOB_FLOW'
    end

    def to_aws_step(job_flow)
      step = {
        :action_on_failure => @action_on_failure,
        :hadoop_jar_step => {
          :jar => @jar
        },
        :name => @name
      }
      step[:hadoop_jar_step][:args] = @arguments + caches_to_aws(@caches)
      step[:hadoop_jar_step].delete(:args) if(step[:hadoop_jar_step][:args].empty?)
      step[:hadoop_jar_step][:main_class] = @main_class if(@main_class)
      step
    end

    def caches_to_aws(caches)
      (caches||[]).map do |cache|
        cache_arg = cache =~ /(\.tar|\.zip|\.tgz)/ ? "-cacheArchive" : "-cacheFile"
        [cache_arg, cache]
      end.flatten
    end

  end

end