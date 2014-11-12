module Elasticity

  class JobFlowStatus

    # http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/ProcessingCycle.html
    ACTIVE_STATES = %w{RUNNING STARTING BOOTSTRAPPING WAITING SHUTTING_DOWN}

    attr_accessor :name
    attr_accessor :jobflow_id
    attr_accessor :state
    attr_accessor :steps
    attr_accessor :created_at
    attr_accessor :started_at
    attr_accessor :ready_at
    attr_accessor :ended_at
    attr_accessor :duration
    attr_accessor :instance_count
    attr_accessor :master_instance_type
    attr_accessor :master_instance_id
    attr_accessor :slave_instance_type
    attr_accessor :last_state_change_reason
    attr_accessor :installed_steps
    attr_accessor :master_public_dns_name
    attr_accessor :normalized_instance_hours

    def initialize
      @steps = []
      @installed_steps = []
    end

    def active?
      ACTIVE_STATES.include? state
    end

    # Create a jobflow from an AWS <member> (Nokogiri::XML::Element):
    #   /DescribeJobFlowsResponse/DescribeJobFlowsResult/JobFlows/member
    def self.from_member_element(xml_element)
      jobflow_status = JobFlowStatus.new

      jobflow_status.name = xml_element.xpath('./Name').text.strip
      jobflow_status.jobflow_id = xml_element.xpath('./JobFlowId').text.strip
      jobflow_status.state = xml_element.xpath('./ExecutionStatusDetail/State').text.strip
      jobflow_status.last_state_change_reason = xml_element.xpath('./ExecutionStatusDetail/LastStateChangeReason').text.strip

      jobflow_status.steps = JobFlowStatusStep.from_members_nodeset(xml_element.xpath('./Steps/member'))

      step_names = jobflow_status.steps.map(&:name)
      Elasticity::JobFlowStep.steps_requiring_installation.each do |step|
        jobflow_status.installed_steps << step if step_names.include?(step.aws_installation_step_name)
      end

      jobflow_status.created_at = Time.parse(xml_element.xpath('./ExecutionStatusDetail/CreationDateTime').text.strip)

      ready_at = xml_element.xpath('./ExecutionStatusDetail/ReadyDateTime').text.strip
      jobflow_status.ready_at = (ready_at == '') ? (nil) : (Time.parse(ready_at))

      started_at = xml_element.xpath('./ExecutionStatusDetail/StartDateTime').text.strip
      jobflow_status.started_at = (started_at == '') ? (nil) : (Time.parse(started_at))

      ended_at = xml_element.xpath('./ExecutionStatusDetail/EndDateTime').text.strip
      jobflow_status.ended_at = (ended_at == '') ? (nil) : (Time.parse(ended_at))

      if jobflow_status.ended_at && jobflow_status.started_at
        jobflow_status.duration = ((jobflow_status.ended_at - jobflow_status.started_at) / 60).to_i
      end

      jobflow_status.instance_count = xml_element.xpath('./Instances/InstanceCount').text.strip
      jobflow_status.master_instance_type = xml_element.xpath('./Instances/MasterInstanceType').text.strip
      master_instance_id = xml_element.xpath('./Instances/MasterInstanceId').text.strip
      jobflow_status.master_instance_id = (master_instance_id == '') ? (nil) : (master_instance_id)
      jobflow_status.slave_instance_type = xml_element.xpath('./Instances/SlaveInstanceType').text.strip

      master_public_dns_name = xml_element.xpath('./Instances/MasterPublicDnsName').text.strip
      jobflow_status.master_public_dns_name = (master_public_dns_name == '') ? (nil) : (master_public_dns_name)

      jobflow_status.normalized_instance_hours = xml_element.xpath('./Instances/NormalizedInstanceHours').text.strip

      jobflow_status
    end

    # Create JobFlows from a collection of AWS <member> nodes (Nokogiri::XML::NodeSet):
    #   /DescribeJobFlowsResponse/DescribeJobFlowsResult/JobFlows
    def self.from_members_nodeset(members_nodeset)
      jobflow_statuses = []
      members_nodeset.each do |member|
        jobflow_statuses << from_member_element(member)
      end
      jobflow_statuses
    end

  end

end
