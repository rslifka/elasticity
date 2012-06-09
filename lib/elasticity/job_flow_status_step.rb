module Elasticity

  class JobFlowStatusStep

    attr_accessor :name
    attr_accessor :state
    attr_accessor :started_at
    attr_accessor :ended_at

    # Create a job flow from an AWS <member> (Nokogiri::XML::Element):
    #   /DescribeJobFlowsResponse/DescribeJobFlowsResult/JobFlows/member/Steps/member
    def self.from_member_element(xml_element)
      job_flow_step = JobFlowStatusStep.new
      job_flow_step.name = xml_element.xpath("./StepConfig/Name").text.strip
      job_flow_step.state = xml_element.xpath("./ExecutionStatusDetail/State").text.strip
      started_at = xml_element.xpath("./ExecutionStatusDetail/StartDateTime").text.strip
      job_flow_step.started_at = (started_at == "") ? (nil) : (Time.parse(started_at))
      ended_at = xml_element.xpath("./ExecutionStatusDetail/EndDateTime").text.strip
      job_flow_step.ended_at = (ended_at == "") ? (nil) : (Time.parse(ended_at))
      job_flow_step
    end

    # Create JobFlowSteps from a collection of AWS <member> nodes (Nokogiri::XML::NodeSet):
    #   /DescribeJobFlowsResponse/DescribeJobFlowsResult/JobFlows/member/Steps/member
    def self.from_members_nodeset(members_nodeset)
      jobflow_steps = []
      members_nodeset.each do |member|
        jobflow_steps << from_member_element(member)
      end
      jobflow_steps
    end

  end

end
