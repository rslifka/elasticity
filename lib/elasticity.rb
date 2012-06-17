require 'base64'
require 'time'

require 'rest_client'
require 'nokogiri'

require 'elasticity/aws_request'
require 'elasticity/emr'

require 'elasticity/hadoop_bootstrap_action'

require 'elasticity/job_flow'
require 'elasticity/job_flow_status'
require 'elasticity/job_flow_status_step'

require 'elasticity/simple_job'

require 'elasticity/custom_jar_job'
require 'elasticity/custom_jar_step'
require 'elasticity/hive_job'
require 'elasticity/hive_step'
require 'elasticity/pig_job'
require 'elasticity/pig_step'

module Elasticity
end
