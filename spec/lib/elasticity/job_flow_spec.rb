require 'spec_helper'

describe Elasticity::JobFlow do

  before do
    describe_jobflows_xml = <<-JOBFLOWS
      <DescribeJobFlowsResponse xmlns="http://elasticmapreduce.amazonaws.com/doc/2009-03-31">
        <DescribeJobFlowsResult>
          <JobFlows>
            <member>
              <ExecutionStatusDetail>
                <State>TERMINATED</State>
              </ExecutionStatusDetail>
              <JobFlowId>j-p</JobFlowId>
              <Name>Pig Job</Name>
            </member>
            <member>
              <ExecutionStatusDetail>
                <State>TERMINATED</State>
              </ExecutionStatusDetail>
              <JobFlowId>j-h</JobFlowId>
              <Name>Hive Job</Name>
            </member>
          </JobFlows>
        </DescribeJobFlowsResult>
      </DescribeJobFlowsResponse>
    JOBFLOWS
    @describe_jobflows_document = Nokogiri::XML(describe_jobflows_xml)
    @describe_jobflows_document.remove_namespaces!
    @members_nodeset = @describe_jobflows_document.xpath('/DescribeJobFlowsResponse/DescribeJobFlowsResult/JobFlows/member')
  end

  describe ".from_xml" do
    it "should return a JobFlow with the appropriate fields initialized" do
      jobflow = Elasticity::JobFlow.from_member_element(@members_nodeset[0])
      jobflow.name.should == "Pig Job"
      jobflow.jobflow_id.should == "j-p"
      jobflow.state.should == "TERMINATED"
    end
  end

  describe ".from_jobflows_nodeset" do
    it "should return JobFlows with the appropriate fields initialized" do
      jobflow = Elasticity::JobFlow.from_members_nodeset(@members_nodeset)
      jobflow.map(&:name).should == ["Pig Job", "Hive Job"]
      jobflow.map(&:jobflow_id).should == ["j-p", "j-h"]
      jobflow.map(&:state).should == ["TERMINATED", "TERMINATED"]
    end
  end

end