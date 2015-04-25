require 'base64'
require 'time'

require 'rest_client'
require 'nokogiri'
require 'fog'

require 'elasticity/aws_session'
require 'elasticity/aws_request_v2'
require 'elasticity/emr'

require 'elasticity/sync_to_s3'

require 'elasticity/bootstrap_action'
require 'elasticity/hadoop_bootstrap_action'
require 'elasticity/hadoop_file_bootstrap_action'
require 'elasticity/ganglia_bootstrap_action'
require 'elasticity/job_flow_step'

require 'elasticity/looper'
require 'elasticity/job_flow'
require 'elasticity/instance_group'

require 'elasticity/job_flow_status'
require 'elasticity/job_flow_status_step'

require 'elasticity/custom_jar_step'
require 'elasticity/setup_hadoop_debugging_step'
require 'elasticity/hive_step'
require 'elasticity/pig_step'
require 'elasticity/streaming_step'
require 'elasticity/script_step'
require 'elasticity/s3distcp_step'

module Elasticity

  class << self
    attr_reader :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def default_configuration
      @configuration = Configuration.new
    end

    def configure
      yield(configuration)
    end
  end

  class Configuration
    attr_accessor :hive_site
  end

end
