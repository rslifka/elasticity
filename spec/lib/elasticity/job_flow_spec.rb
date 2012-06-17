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

  describe '#jobflow_config' do

    before do
      subject.should_receive(:jobflow_preamble).and_return({:preamble => 'PREAMBLE'})
    end

    it 'should incorporate the jobflow preamble' do
      subject.send(:jobflow_config).should be_a_hash_including({:preamble => 'PREAMBLE'})
    end

    describe 'log URI' do

      context 'when a log URI is specified' do
        it 'should incorporate it into the jobflow config' do
          subject.log_uri = 'LOG_URI'
          subject.send(:jobflow_config).should be_a_hash_including({:log_uri => 'LOG_URI'})
        end
      end

      context 'when a log URI is not specified' do
        it 'should not make space for it in the jobflow config' do
          subject.log_uri = nil
          subject.send(:jobflow_config).should_not have_key(:log_uri)
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