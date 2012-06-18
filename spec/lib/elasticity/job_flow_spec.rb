describe Elasticity::JobFlow do

  subject do
    Elasticity::JobFlow.new('access', 'secret')
  end

  its(:action_on_failure) { should == 'TERMINATE_JOB_FLOW' }
  its(:aws_access_key_id) { should == 'access' }
  its(:aws_secret_access_key) { should == 'secret' }
  its(:ec2_key_name) { should == 'default' }
  its(:hadoop_version) { should == '0.20' }
  its(:instance_count) { should == 2 }
  its(:log_uri) { should == nil }
  its(:master_instance_type) { should == 'm1.small' }
  its(:name) { should == 'Elasticity Job Flow' }
  its(:slave_instance_type) { should == 'm1.small' }

  describe '#instance_count=' do

    context 'when set to more than 1' do
      it 'should set the number of instances' do
        subject.instance_count = 10
        subject.instance_count.should == 10
      end
    end

    context 'when set to less than 2' do
      it 'should be an error' do
        expect {
          subject.instance_count = 1
        }.to raise_error(ArgumentError, 'Instance count cannot be set to less than 2 (requested 1)')
      end
    end

  end

  describe '#add_bootstrap_action' do

    context 'when the jobflow is not yet started' do
      it 'should not raise an error' do
        expect {
          subject.add_bootstrap_action(nil)
        }.to_not raise_error
      end
    end

    context 'when the jobflow is already started' do
      xit 'should raise an error'
    end

  end

  describe '#jobflow_config' do

    it 'should incorporate the job flow preamble' do
      subject.stub(:jobflow_preamble).and_return({:preamble => 'PREAMBLE'})
      subject.send(:jobflow_config).should be_a_hash_including({:preamble => 'PREAMBLE'})
    end

    describe 'log URI' do

      context 'when a log URI is specified' do
        let(:jobflow_with_log_uri) do
          Elasticity::JobFlow.new('_', '_').tap do |jf|
            jf.log_uri = 'LOG_URI'
          end
        end
        it 'should incorporate it into the jobflow config' do
          jobflow_with_log_uri.send(:jobflow_config).should be_a_hash_including({:log_uri => 'LOG_URI'})
        end
      end

      context 'when a log URI is not specified' do
        let(:jobflow_with_no_log_uri) do
          Elasticity::JobFlow.new('_', '_').tap do |jf|
            jf.log_uri = nil
          end
        end
        it 'should not make space for it in the jobflow config' do
          jobflow_with_no_log_uri.send(:jobflow_config).should_not have_key(:log_uri)
        end
      end

    end

    describe 'bootstrap actions' do

      context 'when bootstrap actions are specified' do
        let(:hadoop_bootstrap_actions) do
          [
            Elasticity::HadoopBootstrapAction.new('OPTION1', 'VALUE1'),
            Elasticity::HadoopBootstrapAction.new('OPTION1', 'VALUE2'),
            Elasticity::HadoopBootstrapAction.new('OPTION2', 'VALUE3')
          ]
        end
        let(:jobflow_with_bootstrap_actions) do
          Elasticity::JobFlow.new('_', '_').tap do |jf|
            hadoop_bootstrap_actions.each do |action|
              jf.add_bootstrap_action(action)
            end
          end
        end
        it 'should include them in the jobflow config' do
          bootstrap_actions = hadoop_bootstrap_actions.map {|a| a.to_aws_bootstrap_action}
          jobflow_with_bootstrap_actions.send(:jobflow_config).should be_a_hash_including({
            :bootstrap_actions => bootstrap_actions
          })
        end
      end

      context 'when bootstrap actions are not specified' do
        it 'should not make space for them in the jobflow config' do
          subject.send(:jobflow_config).should_not have_key(:bootstrap_actions)
        end
      end

    end

  end

  describe '#jobflow_preamble' do
    it 'should create a jobflow configuration section' do
      subject.send(:jobflow_preamble).should == {
        :name => 'Elasticity Job Flow',
        :instances => {
          :ec2_key_name => 'default',
          :hadoop_version => '0.20',
          :instance_count => 2,
          :master_instance_type => 'm1.small',
          :slave_instance_type => 'm1.small',
        }
      }
    end
  end

end