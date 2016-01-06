module Elasticity

  class JobFlowRunningError < StandardError; end
  class JobFlowNotStartedError < StandardError; end
  class JobFlowMissingStepsError < StandardError; end
  class LogUriMissingError < StandardError; end
  class UnknownPlacementError < StandardError; end

  class JobFlow

    attr_accessor :action_on_failure
    attr_accessor :ec2_key_name
    attr_accessor :name
    attr_accessor :instance_count
    attr_accessor :log_uri
    attr_accessor :tags
    attr_accessor :master_instance_type
    attr_accessor :slave_instance_type
    attr_accessor :ami_version
    attr_accessor :release_label
    attr_accessor :keep_job_flow_alive_when_no_steps
    attr_accessor :ec2_subnet_id
    attr_accessor :placement
    attr_accessor :region
    attr_accessor :visible_to_all_users
    attr_accessor :enable_debugging
    attr_accessor :job_flow_role
    attr_accessor :service_role
    attr_accessor :jobflow_id
    attr_accessor :aws_applications
    attr_accessor :additional_info

    def initialize
      @action_on_failure = 'TERMINATE_JOB_FLOW'
      @name = 'Elasticity Job Flow'
      @keep_job_flow_alive_when_no_steps = false
      self.placement = 'us-east-1a'
      @enable_debugging = false

      @visible_to_all_users = false

      @bootstrap_actions = []
      @aws_applications = []
      @jobflow_steps = []
      @installed_steps = []

      @instance_groups = {}
      set_master_instance_group(Elasticity::InstanceGroup.new)
      set_core_instance_group(Elasticity::InstanceGroup.new)
      @instance_count = 2
      @master_instance_type = 'm1.small'
      @slave_instance_type = 'm1.small'
    end

    def self.from_jobflow_id(jobflow_id, region = 'us-east-1')
      JobFlow.new.tap do |j|
        j.instance_variable_set(:@region, region)
        j.instance_variable_set(:@jobflow_id, jobflow_id)
        j.instance_variable_set(:@installed_steps, ClusterStepStatus.installed_steps(j.cluster_step_status))
      end
    end

    def placement=(new_placement)
      @placement = new_placement
      return unless @placement

      # The region has to be set so we know where to launch the job flow, and it has
      # to be in sync with the placement.  Not setting this will lead to strange, difficult to
      # track errors, for example the job flow won't exist where you think it should, etc.
      if @placement =~ /\w+-\w+-\d+/
        @region = @placement.match(/(\w+-\w+-\d+)/)[0]
      else
        raise UnknownPlacementError, "'#{@placement}' is not a valid EMR placement"
      end
    end

    def enable_debugging=(enabled)
      if enabled
        raise LogUriMissingError, 'To enable debugging, please set a #log_uri' unless @log_uri
      end
      @enable_debugging = enabled
    end

    def instance_count=(count)
      raise ArgumentError, "Instance count cannot be set to less than 2 (requested #{count})" unless count > 1
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

    def ec2_subnet_id=(subnet_id)
      @ec2_subnet_id = subnet_id
      @placement = nil
    end

    def add_bootstrap_action(bootstrap_action)
      if is_jobflow_running?
        raise JobFlowRunningError, 'To modify bootstrap actions, please create a new job flow.'
      end
      @bootstrap_actions << bootstrap_action
    end

    def add_application(application)
      raise JobFlowRunningError, 'To add applications, please create a new job flow.' if is_jobflow_running?
      application = Application.new(name: application) if application.is_a?(String)
      fail "application is not an Elasticity::Application" unless application.is_a?(Application)
      @aws_applications << application
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
        if jobflow_step.requires_installation? && !@installed_steps.include?(jobflow_step.class)
          jobflow_steps.concat(jobflow_step.aws_installation_steps)
        end
        jobflow_steps << jobflow_step.to_aws_step(self)
        emr.add_jobflow_steps(@jobflow_id, jobflow_steps)
      else
        @jobflow_steps << jobflow_step
      end
    end

    def run
      if is_jobflow_running?
        raise JobFlowRunningError, 'Cannot run a job flow multiple times.  To do more with this job flow, please use #add_step.'
      end
      @jobflow_id = emr.run_job_flow(jobflow_config)
    end

    def shutdown
      if !is_jobflow_running?
        raise JobFlowNotStartedError, 'Cannot #shutdown a job flow that has not yet been #run.'
      end
      emr.terminate_jobflows([@jobflow_id])
    end

    def cluster_status
      if !is_jobflow_running?
        raise JobFlowNotStartedError, 'Please #run this job flow before attempting to retrieve status.'
      end
      ClusterStatus.from_aws_data(emr.describe_cluster(@jobflow_id))
    end

    def cluster_step_status
      if !is_jobflow_running?
        raise JobFlowNotStartedError, 'Please #run this job flow before attempting to retrieve status.'
      end
      ClusterStepStatus.from_aws_list_data(emr.list_steps(@jobflow_id))
    end

    def wait_for_completion(&on_wait)
      l = Elasticity::Looper.new(method(:retry_check), on_wait)
      l.go
    end

    private

    def retry_check
      jf_status = cluster_status
      return cluster_status.active?, jf_status
    end

    def emr
      @emr ||= Elasticity::EMR.new(:region => @region)
    end

    def is_jobflow_running?
      !@jobflow_id.nil?
    end

    def jobflow_config
      config = jobflow_preamble
      validate_and_apply_ami_or_release_version(config)
      steps = jobflow_steps
      steps.insert(0, Elasticity::SetupHadoopDebuggingStep.new.to_aws_step(self)) if @enable_debugging
      config[:steps] = steps
      config[:log_uri] = @log_uri if @log_uri
      config[:tags] = jobflow_tags if @tags
      config[:job_flow_role] = @job_flow_role if @job_flow_role
      config[:service_role] = @service_role if @service_role
      config[:additional_info] = @additional_info if @additional_info
      config[:bootstrap_actions] = @bootstrap_actions.map(&:to_aws_bootstrap_action) unless @bootstrap_actions.empty?
      config[:applications] = @aws_applications.map(&:to_hash) if valid_aws_applications?
      config
    end

    def valid_aws_applications?
      !@aws_applications.empty?
    end

    def validate_and_apply_ami_or_release_version(config)
      fail "Please use an EMR release_label not ami_version" if !@aws_applications.empty? && !@ami_version.nil?
      fail "Please set the EMR release_label" if !@aws_applications.empty? && @release_label.nil?
      config[:ami_version] = 'latest' if @ami_version.nil? && release_label.nil?
      config[:ami_version] = @ami_version unless @ami_version.nil?
      config[:release_label] = @release_label unless @release_label.nil?
    end

    def jobflow_tags
      @tags.map do |key, value|
        {
          key: key.to_s,
          value: value
        }
      end
    end

    def jobflow_preamble
      preamble = {
        :name => @name,
        :visible_to_all_users => @visible_to_all_users,
        :instances => {
          :keep_job_flow_alive_when_no_steps => @keep_job_flow_alive_when_no_steps,
          :instance_groups => jobflow_instance_groups,
          :placement => {
            :availability_zone => @placement
          }
        }
      }
      if @ec2_subnet_id
        preamble[:instances].merge!(:ec2_subnet_id => @ec2_subnet_id)
        preamble[:instances].delete(:placement)
      end
      preamble[:instances].merge!(:ec2_key_name => @ec2_key_name) if @ec2_key_name
      preamble
    end

    def jobflow_steps
      steps = []
      @jobflow_steps.each do |step|
        if step.class.send(:requires_installation?) && !@installed_steps.include?(step.class)
          steps.concat(step.class.send(:aws_installation_steps))
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
