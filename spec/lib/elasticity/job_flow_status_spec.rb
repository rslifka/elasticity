describe Elasticity::JobFlowStatus do

  let(:hive_setup_config) do
    <<-XML
      <member>
        <StepConfig>
          <Name>Elasticity - Install Hive</Name>
        </StepConfig>
        <ExecutionStatusDetail>
          <State>FAILED</State>
        </ExecutionStatusDetail>
      </member>
    XML
  end

  let(:pig_setup_config) do
    <<-XML
      <member>
        <StepConfig>
          <Name>Elasticity - Install Pig</Name>
        </StepConfig>
        <ExecutionStatusDetail>
          <State>FAILED</State>
        </ExecutionStatusDetail>
      </member>
    XML
  end

  let(:setup_config) do
    hive_setup_config
  end

  let(:describe_jobflows_xml) do
    <<-XML
      <DescribeJobFlowsResponse xmlns="http://elasticmapreduce.amazonaws.com/doc/2009-03-31">
        <DescribeJobFlowsResult>
          <JobFlows>
            <member>
              <JobFlowId>j-p</JobFlowId>
              <Name>Hive Job 1</Name>
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
                <EndDateTime>
                   2011-11-04T21:49:18Z
                </EndDateTime>
                <State>TERMINATED</State>
              </ExecutionStatusDetail>
              <Steps>
                #{setup_config}
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
                 <MasterPublicDnsName>
                   ec2-107-22-77-99.compute-1.amazonaws.com
                 </MasterPublicDnsName>
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
              <Name>Hive Job 2</Name>
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
    XML
  end

  let(:members_nodeset) do
    describe_jobflows_document = Nokogiri::XML(describe_jobflows_xml)
    describe_jobflows_document.remove_namespaces!
    describe_jobflows_document.xpath('/DescribeJobFlowsResponse/DescribeJobFlowsResult/JobFlows/member')
  end

  let(:single_jobflow) { Elasticity::JobFlowStatus.from_member_element(members_nodeset[0]) }

  let(:multiple_jobflows) { Elasticity::JobFlowStatus.from_members_nodeset(members_nodeset) }

  describe '.from_xml' do
    it 'should return a JobFlow with the appropriate fields initialized' do
      single_jobflow.name.should == 'Hive Job 1'
      single_jobflow.jobflow_id.should == 'j-p'
      single_jobflow.state.should == 'TERMINATED'
      single_jobflow.steps.map(&:name).should == ['Elasticity - Install Hive', 'Run Hive Script']
      single_jobflow.steps.map(&:state).should == %w(FAILED PENDING)
      single_jobflow.created_at.should == Time.parse('2011-10-04T21:49:16Z')
      single_jobflow.started_at.should == Time.parse('2011-10-04T21:49:17Z')
      single_jobflow.ready_at.should == Time.parse('2011-10-04T21:49:18Z')
      single_jobflow.ended_at.should == Time.parse('2011-11-04T21:49:18Z')
      single_jobflow.master_instance_type.should == 'm1.small'
      single_jobflow.slave_instance_type.should == 'm1.small'
      single_jobflow.instance_count.should == '4'
      single_jobflow.last_state_change_reason.should == 'Steps completed with errors'
      single_jobflow.master_public_dns_name.should == 'ec2-107-22-77-99.compute-1.amazonaws.com'
    end
  end

  describe '.from_jobflows_nodeset' do
    it 'should return JobFlows with the appropriate fields initialized' do
      multiple_jobflows.map(&:name).should == ['Hive Job 1', 'Hive Job 2']
      multiple_jobflows.map(&:jobflow_id).should == %w(j-p j-h)
      multiple_jobflows.map(&:state).should == %w(TERMINATED TERMINATED)
      multiple_jobflows.map(&:created_at).should == [Time.parse('2011-10-04T21:49:16Z'), Time.parse('2011-10-04T22:49:16Z')]
      multiple_jobflows.map(&:started_at).should == [Time.parse('2011-10-04T21:49:17Z'), nil]
      multiple_jobflows.map(&:ready_at).should == [Time.parse('2011-10-04T21:49:18Z'), nil]
      multiple_jobflows.map(&:ended_at).should == [Time.parse('2011-11-04T21:49:18Z'), nil]
      multiple_jobflows.map(&:master_instance_type).should == %w(m1.small c1.medium)
      multiple_jobflows.map(&:slave_instance_type).should == %w(m1.small c1.medium)
      multiple_jobflows.map(&:instance_count).should == %w(4 2)
      multiple_jobflows.map(&:last_state_change_reason).should == ['Steps completed with errors', 'Steps completed']
      multiple_jobflows.map(&:master_public_dns_name).should == ['ec2-107-22-77-99.compute-1.amazonaws.com', nil]
    end
  end

  describe '#installed_steps' do

    context 'when nothing has been installed' do
      let(:setup_config) { }
      it 'should be empty' do
        single_jobflow.installed_steps.should == []
      end
    end

    context 'when Hive has been installed by Elasticity' do
      let(:setup_config) { hive_setup_config }
      it 'should include HiveStep' do
        single_jobflow.installed_steps.should == [Elasticity::HiveStep]
      end
    end

    context 'when Pig has been installed by Elasticity' do
      let(:setup_config) { pig_setup_config }
      it 'should include PigStep' do
        single_jobflow.installed_steps.should == [Elasticity::PigStep]
      end
    end

    context 'when more than one step has been installed by Elasticity' do
      let(:setup_config) { hive_setup_config + pig_setup_config }
      it 'should include all of them' do
        single_jobflow.installed_steps.should =~ [Elasticity::HiveStep, Elasticity::PigStep]
      end
    end
  end

end
