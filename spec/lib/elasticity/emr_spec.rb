describe Elasticity::EMR do

  subject do
    Elasticity::EMR.new('ACCESS', 'SECRET')
  end

  describe '.initialize' do

    context 'when arguments are provided' do
      it 'should use the provided arguments' do
        expect(subject.aws_request).to eq(Elasticity::AwsSession.new('ACCESS', 'SECRET', {}))
      end
    end

    context 'when arguments are not provided' do
      before do
        ENV.stub(:[]).with('AWS_ACCESS_KEY_ID').and_return('ENV_ACCESS')
        ENV.stub(:[]).with('AWS_SECRET_ACCESS_KEY').and_return('ENV_SECRET')
      end
      it 'should use environment variables' do
        emr = Elasticity::EMR.new
        emr.aws_request.should == Elasticity::AwsSession.new('ENV_ACCESS', 'ENV_SECRET', {})
      end
    end

  end

  describe '#add_instance_groups' do

    let(:aws_response) do
      <<-JSON
          {
              "InstanceGroupIds": ["ig-1", "ig-2", "ig-3"],
              "JobFlowId": "j-3U7TSX5GZFD8Y"
          }
      JSON
    end

    it 'should send the correct params to AWS' do
      Elasticity::AwsSession.any_instance.should_receive(:submit).with({
        :operation => 'AddInstanceGroups',
        :job_flow_id => 'JOBFLOW_ID',
        :instance_groups => ['INSTANCE_GROUP_CONFIGS']
      }).and_return(aws_response)
      subject.add_instance_groups('JOBFLOW_ID', ['INSTANCE_GROUP_CONFIGS'])
    end

    describe 'return values' do
      it 'should return an array of the new instance groups IDs' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).and_return(aws_response)
        subject.add_instance_groups('', []).should == ['ig-1', 'ig-2', 'ig-3']
      end
    end

    context 'when a block is given' do
      it 'should yield the submission results' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).and_return(aws_response)
        subject.add_instance_groups('', []) do |result|
          result.should == aws_response
        end
      end
    end

  end

  describe '#add_jobflow_steps' do

    it 'should add the specified steps to the job flow' do
      Elasticity::AwsSession.any_instance.should_receive(:submit).with({
        :operation => 'AddJobFlowSteps',
        :job_flow_id => 'JOBFLOW_ID',
        :steps => ['_']
      })
      subject.add_jobflow_steps('JOBFLOW_ID', ['_'])
    end

    context 'when a block is given' do
      let(:result) { 'RESULT' }
      it 'should yield the submission results' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).and_return(result)
        subject.add_jobflow_steps('', {}) do |xml|
          xml.should == 'RESULT'
        end
      end
    end

  end

  describe '#add_tags' do

    it 'should modify the jobflow tags' do
      Elasticity::AwsSession.any_instance.should_receive(:submit).with({
          :operation => 'AddTags',
          :resource_id => 'JOBFLOW_ID',
          :tags => [
            {
              :key => 'TEST_KEY',
              :value => 'TEST_VALUE'
            },
            {
              :key => 'TEST_KEY_ONLY'
            }
          ]
        })
      subject.add_tags('JOBFLOW_ID', [{:key => 'TEST_KEY', :value => 'TEST_VALUE'}, {:key => 'TEST_KEY_ONLY'}])
    end

    context 'when a block is given' do
      it 'should yield the submission results' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).and_return('RESULT')
        subject.add_tags('', {}) do |result|
          result.should == 'RESULT'
        end
      end
    end

  end

  describe '#describe_cluster' do

    let(:aws_result) {
      <<-JSON
        {"Key" : "Value"}
      JSON
    }

    it 'should describe the specified jobflow' do
      Elasticity::AwsSession.any_instance.should_receive(:submit).with({
          :operation => 'DescribeCluster',
          :cluster_id => 'CLUSTER_ID'
        }).and_return(aws_result)
      expect(subject.describe_cluster('CLUSTER_ID')).to eql(JSON.parse(aws_result))
    end

    context 'when a block is given' do
      it 'should yield the submission results' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).and_return(aws_result)
        subject.describe_cluster({}) do |result|
          result.should == aws_result
        end
      end
    end

  end

  describe '#list_instance_groups' do

    let(:aws_result) {
      <<-JSON
        {"Key" : "Value"}
      JSON
    }

    it 'should list the instance groups in the specified jobflow' do
      Elasticity::AwsSession.any_instance.should_receive(:submit).with({
          :operation => 'ListInstanceGroups',
          :cluster_id => 'CLUSTER_ID'
        }).and_return(aws_result)
      expect(subject.list_instance_groups('CLUSTER_ID')).to eql(JSON.parse(aws_result))
    end

    context 'when a block is given' do
      it 'should yield the submission results' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).and_return(aws_result)
        subject.list_instance_groups({}) do |result|
          result.should == aws_result
        end
      end
    end

  end

  describe '#list_bootstrap_actions' do

    let(:aws_result) {
      <<-JSON
        {"Key" : "Value"}
      JSON
    }

    it 'should list the bootstrap actions in the specified jobflow' do
      Elasticity::AwsSession.any_instance.should_receive(:submit).with({
          :operation => 'ListBootstrapActions',
          :cluster_id => 'CLUSTER_ID'
        }).and_return(aws_result)
      expect(subject.list_bootstrap_actions('CLUSTER_ID')).to eql(JSON.parse(aws_result))
    end

    context 'when a block is given' do
      it 'should yield the submission results' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).and_return(aws_result)
        subject.list_bootstrap_actions({}) do |result|
          result.should == aws_result
        end
      end
    end

  end

  describe '#modify_instance_groups' do

    it 'should modify the specified instance groups' do
      Elasticity::AwsSession.any_instance.should_receive(:submit).with({
        :operation => 'ModifyInstanceGroups',
        :instance_groups => [{
          :instance_group_id => 'ig-2T1HNUO61BG3O',
          :instance_count => 2
        }]
      })
      subject.modify_instance_groups({'ig-2T1HNUO61BG3O' => 2})
    end

    context 'when a block is given' do
      let(:result) { '_' }
      it 'should yield the submission results' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).and_return(result)
        subject.modify_instance_groups({}) do |xml|
          xml.should == '_'
        end
      end
    end

  end

  describe '#run_jobflow' do

    let(:json_response) {
      <<-JSON
        {"JobFlowId" : "TEST_JOBFLOW_ID"}
      JSON
    }

    it 'should start the specified job flow' do
      Elasticity::AwsSession.any_instance.should_receive(:submit).with({
        :operation => 'RunJobFlow',
        :jobflow_params => '_'
      }).and_return(json_response)
      subject.run_job_flow({:jobflow_params => '_'})
    end

    describe 'jobflow response handling' do
      it 'should return the ID of the running job flow' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).and_return(json_response)
        subject.run_job_flow({}).should == 'TEST_JOBFLOW_ID'
      end
    end

    context 'when a block is given' do
      it 'should yield the submission results' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).and_return(json_response)
        subject.run_job_flow({}) do |response|
          response.should == json_response
        end
      end
    end

  end

  describe '#terminate_jobflows' do

    context 'when one jobflow is specified' do
      it 'should terminate the jobflow' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).with({
            :operation => 'TerminateJobFlows',
            :job_flow_ids => ['j-1']
          })
        subject.terminate_jobflows(['j-1'])
      end
    end

    context 'when more then one jobflow is specified' do
      it 'should terminate all of the jobflows' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).with({
            :operation => 'TerminateJobFlows',
            :job_flow_ids => ['j-1', 'j-2']
          })
        subject.terminate_jobflows(['j-1', 'j-2'])
      end
    end

    context 'when a block is given' do
      let(:result) { '_' }
      it 'should yield the termination results' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).and_return(result)
        subject.terminate_jobflows('j-1') do |xml|
          xml.should == '_'
        end
      end
    end

  end

  describe '#remove_tags' do

    it 'should remove the jobflow tags' do
      Elasticity::AwsSession.any_instance.should_receive(:submit).with({
          :operation => 'RemoveTags',
          :resource_id => 'JOBFLOW_ID',
          :tag_keys => ['TEST_KEY', 'TEST_KEY_ONLY']
        })
      subject.remove_tags('JOBFLOW_ID', ['TEST_KEY', 'TEST_KEY_ONLY'])
    end

    context 'when a block is given' do
      it 'should yield the submission results' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).and_return('RESULT')
        subject.remove_tags('', {}) do |result|
          result.should == 'RESULT'
        end
      end
    end

  end

  describe '#set_termination_protection' do

    context 'when protection is enabled' do
      it 'should enable protection on the specified jobflows' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).with({
          :operation => 'SetTerminationProtection',
          :termination_protected => true,
          :job_flow_ids => ['jobflow1', 'jobflow2']
        })
        subject.set_termination_protection(['jobflow1', 'jobflow2'], true)
      end
    end

    context 'when protection is disabled' do
      it 'should disable protection on the specified jobflows' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).with({
          :operation => 'SetTerminationProtection',
          :termination_protected => false,
          :job_flow_ids => ['jobflow1', 'jobflow2']
        })
        subject.set_termination_protection(['jobflow1', 'jobflow2'], false)
      end
    end

    context 'when protection is not specified' do
      it 'should enable protection on the specified jobflows' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).with({
          :operation => 'SetTerminationProtection',
          :termination_protected => true,
          :job_flow_ids => ['jobflow1', 'jobflow2']
        })
        subject.set_termination_protection(['jobflow1', 'jobflow2'])
      end
    end

    context 'when a block is given' do
      let(:result) { '_' }
      it 'should yield the termination results' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).and_return(result)
        subject.set_termination_protection([]) do |xml|
          xml.should == '_'
        end
      end
    end

  end

  describe '#set_visible_to_all_users' do

    context 'when visibility is enabled' do
      it 'should enable visibility on the specified jobflows' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).with({
            :operation => 'SetVisibleToAllUsers',
            :visible_to_all_users => true,
            :job_flow_ids => ['jobflow1', 'jobflow2']
          })
        subject.set_visible_to_all_users(['jobflow1', 'jobflow2'], true)
      end
    end

    context 'when visibility is disabled' do
      it 'should disable protection on the specified jobflows' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).with({
            :operation => 'SetVisibleToAllUsers',
            :visible_to_all_users => false,
            :job_flow_ids => ['jobflow1', 'jobflow2']
          })
        subject.set_visible_to_all_users(['jobflow1', 'jobflow2'], false)
      end
    end

    context 'when visibility is not specified' do
      it 'should enable protection on the specified jobflows' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).with({
            :operation => 'SetVisibleToAllUsers',
            :visible_to_all_users => true,
            :job_flow_ids => ['jobflow1', 'jobflow2']
          })
        subject.set_visible_to_all_users(['jobflow1', 'jobflow2'])
      end
    end

    context 'when a block is given' do
      let(:aws_response) { '_' }
      it 'should yield the termination results' do
        Elasticity::AwsSession.any_instance.should_receive(:submit).and_return(aws_response)
        subject.set_visible_to_all_users([]) do |result|
          result.should == '_'
        end
      end
    end

  end

  describe '#direct' do
    let(:params) { {:foo => 'bar'} }

    it 'should pass through directly to the request and return the results of the request' do
      Elasticity::AwsSession.any_instance.should_receive(:submit).with(params).and_return('RESULT')
      subject.direct(params).should == 'RESULT'
    end
  end

  describe '#==' do
    let(:emr1) { Elasticity::EMR.new('ACCESS1', 'SECRET1') }
    let(:emr2) { Elasticity::EMR.new('ACCESS2', 'SECRET2') }

    let(:same_object) { emr1 }
    let(:same_values) { Elasticity::EMR.new('ACCESS1', 'SECRET1') }
    let(:diff_type) { Object.new }

    it 'should pass comparison checks' do
      emr1.should == same_object
      emr1.should == same_values
      emr1.should_not == diff_type
    end
  end

end
