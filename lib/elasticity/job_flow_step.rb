module Elasticity

  class JobFlowStep

    attr_accessor :name
    attr_accessor :state
    attr_accessor :started_at
    attr_accessor :ended_at

    class << self

      # Create a job flow from an AWS <member> (Nokogiri::XML::Element):
      #   /DescribeJobFlowsResponse/DescribeJobFlowsResult/JobFlows/member/Steps/member
      def from_member_element(xml_element)
        job_flow_step = JobFlowStep.new
        job_flow_step.name = xml_element.xpath("./StepConfig/Name").text.strip
        job_flow_step.state = xml_element.xpath("./ExecutionStatusDetail/State").text.strip
        job_flow_step.started_at = xml_element.xpath("./ExecutionStatusDetail/StartDateTime").text.strip
        job_flow_step.ended_at = xml_element.xpath("./ExecutionStatusDetail/EndDateTime").text.strip
        job_flow_step
      end

      # Create JobFlowSteps from a collection of AWS <member> nodes (Nokogiri::XML::NodeSet):
      #   /DescribeJobFlowsResponse/DescribeJobFlowsResult/JobFlows/member/Steps/member
      def from_members_nodeset(members_nodeset)
        jobflow_steps = []
        members_nodeset.each do |member|
          jobflow_steps << from_member_element(member)
        end
        jobflow_steps
      end
    end

  end

end
