require 'spec_helper'

describe Elasticity::JobFlow do

  before do
    describe_jobflows_xml = <<-JOBFLOWS
      <DescribeJobFlowsResponse xmlns="http://elasticmapreduce.amazonaws.com/doc/2009-03-31">
        <DescribeJobFlowsResult>
          <JobFlows>
            <member>
              <JobFlowId>j-p</JobFlowId>
              <Name>Pig Job</Name>
              <ExecutionStatusDetail>
                <CreationDateTime>
                   2011-10-04T21:49:16Z
                </CreationDateTime>
                <LastStateChangeReason>
                   Steps completed with errors
                </LastStateChangeReason>
                <StartDateTime>
                   2011-10-04T21:49:17Z
                </StartDateTime>
                <ReadyDateTime>
                   2011-10-04T21:49:18Z
                </ReadyDateTime>
                <State>TERMINATED</State>
              </ExecutionStatusDetail>
              <Steps>
                <member>
                  <StepConfig>
                    <Name>Setup Hive</Name>
                  </StepConfig>
                  <ExecutionStatusDetail>
                    <State>FAILED</State>
                  </ExecutionStatusDetail>
                </member>
                <member>
                  <StepConfig>
                    <Name>Run Hive Script</Name>
                  </StepConfig>
                  <ExecutionStatusDetail>
                    <State>PENDING</State>
                  </ExecutionStatusDetail>
                </member>
              </Steps>
              <Instances>
                 <Placement>
                    <AvailabilityZone>
                      eu-west-1a
                    </AvailabilityZone>
                 </Placement>
                 <SlaveInstanceType>
                    m1.small
                 </SlaveInstanceType>
                 <MasterInstanceType>
                    m1.small
                 </MasterInstanceType>
                 <Ec2KeyName>
                    myec2keyname
                 </Ec2KeyName>
                 <InstanceCount>
                    4
                 </InstanceCount>
              </Instances>
            </member>
            <member>
              <JobFlowId>j-h</JobFlowId>
              <Name>Hive Job</Name>
              <ExecutionStatusDetail>
                <CreationDateTime>
                   2011-10-04T22:49:16Z
                </CreationDateTime>
                <StartDateTime>

                </StartDateTime>
                <ReadyDateTime>
                   
                </ReadyDateTime>
                <State>
                  TERMINATED
                </State>
                <LastStateChangeReason>
                  Steps completed
                </LastStateChangeReason>
              </ExecutionStatusDetail>
              <Instances>
                 <Placement>
                    <AvailabilityZone>
                      eu-west-1b
                    </AvailabilityZone>
                 </Placement>
                 <SlaveInstanceType>
                    c1.medium
                 </SlaveInstanceType>
                 <MasterInstanceType>
                    c1.medium
                 </MasterInstanceType>
                 <Ec2KeyName>
                    myec2keyname
                 </Ec2KeyName>
                 <InstanceCount>
                    2
                 </InstanceCount>
              </Instances>
            </member>
          </JobFlows>
        </DescribeJobFlowsResult>
      </DescribeJobFlowsResponse>
    JOBFLOWS
    describe_jobflows_document = Nokogiri::XML(describe_jobflows_xml)
    describe_jobflows_document.remove_namespaces!
    @members_nodeset = describe_jobflows_document.xpath('/DescribeJobFlowsResponse/DescribeJobFlowsResult/JobFlows/member')
  end

  describe ".from_xml" do
    it "should return a JobFlow with the appropriate fields initialized" do
      jobflow = Elasticity::JobFlow.from_member_element(@members_nodeset[0])
      jobflow.name.should == "Pig Job"
      jobflow.jobflow_id.should == "j-p"
      jobflow.state.should == "TERMINATED"
      jobflow.steps.map(&:name).should == ["Setup Hive", "Run Hive Script"]
      jobflow.steps.map(&:state).should == ["FAILED", "PENDING"]
      jobflow.created_at.should == Time.parse("2011-10-04T21:49:16Z")
      jobflow.started_at.should == Time.parse("2011-10-04T21:49:17Z")
      jobflow.ready_at.should == Time.parse("2011-10-04T21:49:18Z")
      jobflow.master_instance_type.should == "m1.small"
      jobflow.slave_instance_type.should == "m1.small"
      jobflow.instance_count.should == "4"
      jobflow.last_state_change_reason.should == "Steps completed with errors"
    end
  end

  describe ".from_jobflows_nodeset" do
    it "should return JobFlows with the appropriate fields initialized" do
      jobflow = Elasticity::JobFlow.from_members_nodeset(@members_nodeset)
      jobflow.map(&:name).should == ["Pig Job", "Hive Job"]
      jobflow.map(&:jobflow_id).should == ["j-p", "j-h"]
      jobflow.map(&:state).should == ["TERMINATED", "TERMINATED"]
      jobflow.map(&:created_at).should == [Time.parse("2011-10-04T21:49:16Z"), Time.parse("2011-10-04T22:49:16Z")]
      jobflow.map(&:started_at).should == [Time.parse("2011-10-04T21:49:17Z"), nil]
      jobflow.map(&:ready_at).should == [Time.parse("2011-10-04T21:49:18Z"), nil]
      jobflow.map(&:master_instance_type).should == ["m1.small","c1.medium"]
      jobflow.map(&:slave_instance_type).should == ["m1.small", "c1.medium"]
      jobflow.map(&:instance_count).should == ["4","2"]
      jobflow.map(&:last_state_change_reason).should == ["Steps completed with errors", "Steps completed"]
    end
  end

end
