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

  let(:started_at) do
    <<-XML
      <StartDateTime>
        2011-10-04T21:49:17Z
      </StartDateTime>
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
                #{started_at}
                <ReadyDateTime>
                   2011-10-04T21:49:18Z
                </ReadyDateTime>
                <EndDateTime>
                   2011-10-05T21:49:18Z
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
                 <NormalizedInstanceHours>
                   0
                 </NormalizedInstanceHours>
                 <Placement>
                    <AvailabilityZone>
                      eu-west-1a
                    </AvailabilityZone>
                 </Placement>
                 <SlaveInstanceType>
                    m1.small
                 </SlaveInstanceType>
                 <MasterInstanceId>
                    i-15a4417c
                 </MasterInstanceId>
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
                <State>
                  TERMINATED
                </State>
                <LastStateChangeReason>
                  Steps completed
                </LastStateChangeReason>
              </ExecutionStatusDetail>
              <Instances>
                 <NormalizedInstanceHours>
                   4
                 </NormalizedInstanceHours>
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

  let(:single_jobflow_status) { Elasticity::JobFlowStatus.from_member_element(members_nodeset[0]) }

  let(:multiple_jobflow_statuses) { Elasticity::JobFlowStatus.from_members_nodeset(members_nodeset) }

  describe '.from_xml' do
    it 'should return a JobFlowStatus with the appropriate fields initialized' do
      single_jobflow_status.name.should == 'Hive Job 1'
      single_jobflow_status.jobflow_id.should == 'j-p'
      single_jobflow_status.state.should == 'TERMINATED'
      single_jobflow_status.steps.map(&:name).should == ['Elasticity - Install Hive', 'Run Hive Script']
      single_jobflow_status.steps.map(&:state).should == %w(FAILED PENDING)
      single_jobflow_status.created_at.should == Time.parse('2011-10-04T21:49:16Z')
      single_jobflow_status.started_at.should == Time.parse('2011-10-04T21:49:17Z')
      single_jobflow_status.ready_at.should == Time.parse('2011-10-04T21:49:18Z')
      single_jobflow_status.ended_at.should == Time.parse('2011-10-05T21:49:18Z')
      single_jobflow_status.duration.should == 1440
      single_jobflow_status.master_instance_id.should == 'i-15a4417c'
      single_jobflow_status.master_instance_type.should == 'm1.small'
      single_jobflow_status.slave_instance_type.should == 'm1.small'
      single_jobflow_status.instance_count.should == '4'
      single_jobflow_status.last_state_change_reason.should == 'Steps completed with errors'
      single_jobflow_status.master_public_dns_name.should == 'ec2-107-22-77-99.compute-1.amazonaws.com'
      single_jobflow_status.normalized_instance_hours.should == '0'
    end

    context 'when the jobflow never started' do
      let(:started_at) {}
      it 'should have a nil duration' do
        single_jobflow_status.started_at.should == nil
        single_jobflow_status.duration.should == nil
      end
    end
  end

  describe '.from_jobflow_statuses_nodeset' do
    it 'should return JobFlowStatuses with the appropriate fields initialized' do
      multiple_jobflow_statuses.map(&:name).should == ['Hive Job 1', 'Hive Job 2']
      multiple_jobflow_statuses.map(&:jobflow_id).should == %w(j-p j-h)
      multiple_jobflow_statuses.map(&:state).should == %w(TERMINATED TERMINATED)
      multiple_jobflow_statuses.map(&:created_at).should == [Time.parse('2011-10-04T21:49:16Z'), Time.parse('2011-10-04T22:49:16Z')]
      multiple_jobflow_statuses.map(&:started_at).should == [Time.parse('2011-10-04T21:49:17Z'), nil]
      multiple_jobflow_statuses.map(&:ready_at).should == [Time.parse('2011-10-04T21:49:18Z'), nil]
      multiple_jobflow_statuses.map(&:ended_at).should == [Time.parse('2011-10-05T21:49:18Z'), nil]
      multiple_jobflow_statuses.map(&:duration).should == [1440, nil]
      multiple_jobflow_statuses.map(&:master_instance_id).should == ['i-15a4417c', '']
      multiple_jobflow_statuses.map(&:master_instance_type).should == %w(m1.small c1.medium)
      multiple_jobflow_statuses.map(&:slave_instance_type).should == %w(m1.small c1.medium)
      multiple_jobflow_statuses.map(&:instance_count).should == %w(4 2)
      multiple_jobflow_statuses.map(&:last_state_change_reason).should == ['Steps completed with errors', 'Steps completed']
      multiple_jobflow_statuses.map(&:master_public_dns_name).should == ['ec2-107-22-77-99.compute-1.amazonaws.com', nil]
      multiple_jobflow_statuses.map(&:normalized_instance_hours).should == %w(0 4)
    end
  end

  describe '#installed_steps' do

    context 'when nothing has been installed' do
      let(:setup_config) { }
      it 'should be empty' do
        single_jobflow_status.installed_steps.should == []
      end
    end

    context 'when Hive has been installed by Elasticity' do
      let(:setup_config) { hive_setup_config }
      it 'should include HiveStep' do
        single_jobflow_status.installed_steps.should == [Elasticity::HiveStep]
      end
    end

    context 'when Pig has been installed by Elasticity' do
      let(:setup_config) { pig_setup_config }
      it 'should include PigStep' do
        single_jobflow_status.installed_steps.should == [Elasticity::PigStep]
      end
    end

    context 'when more than one step has been installed by Elasticity' do
      let(:setup_config) { hive_setup_config + pig_setup_config }
      it 'should include all of them' do
        single_jobflow_status.installed_steps.should =~ [Elasticity::HiveStep, Elasticity::PigStep]
      end
    end
  end

end
