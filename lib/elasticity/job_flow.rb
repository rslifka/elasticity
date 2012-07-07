module Elasticity

  class JobFlowRunningError < StandardError; end
  class JobFlowNotStartedError < StandardError; end
  class JobFlowMissingStepsError < StandardError; end

  class JobFlow

    attr_accessor :action_on_failure
    attr_accessor :ec2_key_name
    attr_accessor :name
    attr_accessor :hadoop_version
    attr_accessor :instance_count
    attr_accessor :log_uri
    attr_accessor :master_instance_type
    attr_accessor :slave_instance_type
    attr_accessor :ami_version
    attr_accessor :keep_job_flow_alive_when_no_steps
    attr_accessor :ec2_subnet_id

    def initialize(access, secret)
      @action_on_failure = 'TERMINATE_JOB_FLOW'
      @ec2_key_name = 'default'
      @hadoop_version = '0.20.205'
      @name = 'Elasticity Job Flow'
      @ami_version = 'latest'
      @keep_job_flow_alive_when_no_steps = false

      @bootstrap_actions = []
      @jobflow_steps = []
      @installed_steps = []

      @instance_groups = {}
      set_master_instance_group(Elasticity::InstanceGroup.new)
      set_core_instance_group(Elasticity::InstanceGroup.new)

      @instance_count = 2
      @master_instance_type = 'm1.small'
      @slave_instance_type = 'm1.small'

      @emr = Elasticity::EMR.new(access, secret)
    end

    def instance_count=(count)
      raise ArgumentError, 'Instance count cannot be set to less than 2 (requested 1)' unless count > 1
      @instance_groups[:core].count = count - 1
      @instance_count = count
    end

    def master_instance_type=(type)
      @instance_groups[:master].type = type
      @master_instance_type = type
    end

    def slave_instance_type=(type)
      @instance_groups[:core].type = type
      @slave_instance_type = type
    end

    def add_bootstrap_action(bootstrap_action)
      raise_if is_jobflow_running?, JobFlowRunningError, 'To modify bootstrap actions, please create a new job flow.'
      @bootstrap_actions << bootstrap_action
    end

    def set_master_instance_group(instance_group)
      instance_group.role = 'MASTER'
      @instance_groups[:master] = instance_group
    end

    def set_core_instance_group(instance_group)
      instance_group.role = 'CORE'
      @instance_groups[:core] = instance_group
    end

    def set_task_instance_group(instance_group)
      instance_group.role = 'TASK'
      @instance_groups[:task] = instance_group
    end

    def add_step(jobflow_step)
      if is_jobflow_running?
        jobflow_steps = []
        if jobflow_step.class.send(:requires_installation?) && !@installed_steps.include?(jobflow_step.class)
          jobflow_steps << jobflow_step.class.send(:aws_installation_step)
        end
        jobflow_steps << jobflow_step.to_aws_step(self)
        @emr.add_jobflow_steps(@jobflow_id, {:steps => jobflow_steps})
      else
        @jobflow_steps << jobflow_step
      end
    end

    def run
      raise_if @jobflow_steps.empty?, JobFlowMissingStepsError, 'Cannot run a job flow without adding steps.  Please use #add_step.'
      raise_if is_jobflow_running?, JobFlowRunningError, 'Cannot run a job flow multiple times.  To do more with this job flow, please use #add_step.'
      @jobflow_id ||= @emr.run_job_flow(jobflow_config)
    end

    def shutdown
      raise_unless is_jobflow_running?, JobFlowNotStartedError, 'Cannot #shutdown a job flow that has not yet been #run.'
      @emr.terminate_jobflows(@jobflow_id)
    end

    def status
      raise_unless is_jobflow_running?, JobFlowNotStartedError, 'Please #run this job flow before attempting to retrieve status.'
      @emr.describe_jobflow(@jobflow_id)
    end

    private

    def is_jobflow_running?
      @jobflow_id
    end

    def jobflow_config
      config = jobflow_preamble
      config[:steps] = jobflow_steps
      config[:log_uri] = @log_uri if @log_uri
      config[:bootstrap_actions] = @bootstrap_actions.map{|a| a.to_aws_bootstrap_action} unless @bootstrap_actions.empty?
      config
    end

    def jobflow_preamble
      preamble = {
        :name => @name,
        :ami_version => @ami_version,
        :instances => {
          :keep_job_flow_alive_when_no_steps => @keep_job_flow_alive_when_no_steps,
          :ec2_key_name => @ec2_key_name,
          :hadoop_version => @hadoop_version,
          :instance_groups => jobflow_instance_groups
        }
      }
      preamble.merge!(:ec2_subnet_id => @ec2_subnet_id) if @ec2_subnet_id
      preamble
    end

    def jobflow_steps
      steps = []
      @jobflow_steps.each do |step|
        if step.class.send(:requires_installation?) && !@installed_steps.include?(step.class)
          steps << step.class.send(:aws_installation_step)
          @installed_steps << step.class
        end
        steps << step.to_aws_step(self)
      end
      steps
    end

    def jobflow_instance_groups
      groups = [:master, :core, :task].map{|role| @instance_groups[role]}.compact
      groups.map(&:to_aws_instance_config)
    end

  end

end