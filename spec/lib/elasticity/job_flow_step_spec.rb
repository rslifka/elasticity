require 'spec_helper'

describe Elasticity::JobFlowStep do

  before do
    describe_jobflows_xml = <<-JOBFLOWS
      <DescribeJobFlowsResponse xmlns="http://elasticmapreduce.amazonaws.com/doc/2009-03-31">
        <DescribeJobFlowsResult>
          <JobFlows>
            <member>
              <JobFlowId>j-p</JobFlowId>
              <Name>Pig Job</Name>
              <ExecutionStatusDetail>
                <State>TERMINATED</State>
              </ExecutionStatusDetail>
              <Steps>
                <member>
                  <StepConfig>
                    <Name>Setup Hive</Name>
                  </StepConfig>
                  <ExecutionStatusDetail>
                    <State>FAILED</State>
                    <StartDateTime>
                       2011-10-04T21:49:16Z
                    </StartDateTime>
                    <EndDateTime>
                       2011-10-04T21:51:16Z
                    </EndDateTime>
                  </ExecutionStatusDetail>
                </member>
                <member>
                  <StepConfig>
                    <Name>Run Hive Script</Name>
                  </StepConfig>
                  <ExecutionStatusDetail>
                    <State>PENDING</State>
                    <StartDateTime>
                       2011-10-04T21:51:18Z
                    </StartDateTime>
                    <EndDateTime>
                    </EndDateTime>
                  </ExecutionStatusDetail>
                </member>
              </Steps>
            </member>
          </JobFlows>
        </DescribeJobFlowsResult>
      </DescribeJobFlowsResponse>
    JOBFLOWS
    describe_jobflows_document = Nokogiri::XML(describe_jobflows_xml)
    describe_jobflows_document.remove_namespaces!
    @members_nodeset = describe_jobflows_document.xpath('/DescribeJobFlowsResponse/DescribeJobFlowsResult/JobFlows/member/Steps/member')
  end

  describe ".from_xml" do
    it "should return a JobFlowStep with the appropriate fields initialized" do
      jobflow_step = Elasticity::JobFlowStep.from_member_element(@members_nodeset[0])
      jobflow_step.name.should == "Setup Hive"
      jobflow_step.state.should == "FAILED"
      jobflow_step.started_at.should == "2011-10-04T21:49:16Z"
      jobflow_step.ended_at.should == "2011-10-04T21:51:16Z"
    end
  end

  describe ".from_steps_nodeset" do
    it "should return JobFlowSteps with the appropriate fields initialized" do
      jobflow_steps = Elasticity::JobFlowStep.from_members_nodeset(@members_nodeset)
      jobflow_steps.map(&:name).should == ["Setup Hive", "Run Hive Script"]
      jobflow_steps.map(&:state).should == ["FAILED", "PENDING"]
      jobflow_steps.map(&:started_at).should == ["2011-10-04T21:49:16Z", "2011-10-04T21:51:18Z"]
      jobflow_steps.map(&:ended_at).should == ["2011-10-04T21:51:16Z", ""]
    end
  end


end
