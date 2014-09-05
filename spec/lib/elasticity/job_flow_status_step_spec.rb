describe Elasticity::JobFlowStatusStep do

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
                    <CreationDateTime>
                      2011-10-04T21:46:16Z
                    </CreationDateTime>
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
                    <CreationDateTime>
                    </CreationDateTime>
                    <StartDateTime>
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
      jobflow_step = Elasticity::JobFlowStatusStep.from_member_element(@members_nodeset[0])
      jobflow_step.name.should == "Setup Hive"
      jobflow_step.state.should == "FAILED"
      jobflow_step.created_at.should == Time.parse("2011-10-04T21:46:16Z")
      jobflow_step.started_at.should == Time.parse("2011-10-04T21:49:16Z")
      jobflow_step.ended_at.should == Time.parse("2011-10-04T21:51:16Z")
    end
  end

  describe ".from_steps_nodeset" do
    it "should return JobFlowSteps with the appropriate fields initialized" do
      jobflow_steps = Elasticity::JobFlowStatusStep.from_members_nodeset(@members_nodeset)
      jobflow_steps.map(&:name).should == ["Setup Hive", "Run Hive Script"]
      jobflow_steps.map(&:state).should == ["FAILED", "PENDING"]
      jobflow_steps.map(&:created_at).should == [Time.parse("2011-10-04T21:46:16Z"), nil]
      jobflow_steps.map(&:started_at).should == [Time.parse("2011-10-04T21:49:16Z"), nil]
      jobflow_steps.map(&:ended_at).should == [Time.parse("2011-10-04T21:51:16Z"), nil]
    end
  end


end
