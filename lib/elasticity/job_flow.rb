module Elasticity

  class JobFlow

    attr_accessor :name
    attr_accessor :jobflow_id
    attr_accessor :state
    attr_accessor :steps

    def initialize
      @steps = []
    end

    class << self

      # Create a jobflow from an AWS <member> (Nokogiri::XML::Element):
      #   /DescribeJobFlowsResponse/DescribeJobFlowsResult/JobFlows/member
      def from_member_element(xml_element)
        jobflow = JobFlow.new
        jobflow.name = xml_element.xpath("./Name").text
        jobflow.jobflow_id = xml_element.xpath("./JobFlowId").text
        jobflow.state = xml_element.xpath("./ExecutionStatusDetail/State").text
        jobflow.steps = JobFlowStep.from_members_nodeset(xml_element.xpath("./Steps/member"))
        jobflow
      end

      # Create JobFlows from a collection of AWS <member> nodes (Nokogiri::XML::NodeSet):
      #   /DescribeJobFlowsResponse/DescribeJobFlowsResult/JobFlows
      def from_members_nodeset(members_nodeset)
        jobflows = []
        members_nodeset.each do |member|
          jobflows << from_member_element(member)
        end
        jobflows
      end

    end

  end

end