describe Elasticity::StreamingStep do

  subject do
    Elasticity::StreamingStep.new('INPUT_BUCKET', 'OUTPUT_BUCKET', 'MAPPER', 'REDUCER')
  end

  it { should be_a Elasticity::JobFlowStep }

  its(:name) { should == 'Elasticity Streaming Step' }
  its(:action_on_failure) { should == 'TERMINATE_JOB_FLOW' }
  its(:input_bucket) { should == 'INPUT_BUCKET' }
  its(:output_bucket) { should == 'OUTPUT_BUCKET' }
  its(:mapper) { should == 'MAPPER' }
  its(:reducer) { should == 'REDUCER' }

  describe '#to_aws_step' do

    it 'should convert to aws step format' do
      subject.to_aws_step(Elasticity::JobFlow.new('_', '_')).should == {
        :name => 'Elasticity Streaming Step',
        :action_on_failure => 'TERMINATE_JOB_FLOW',
        :hadoop_jar_step => {
          :jar => '/home/hadoop/contrib/streaming/hadoop-streaming.jar',
          :args => %w(-input INPUT_BUCKET -output OUTPUT_BUCKET -mapper MAPPER -reducer REDUCER),
        },
      }
    end

  end

  describe '.requires_installation?' do
    it 'should not require installation' do
      Elasticity::StreamingStep.requires_installation?.should be_false
    end
  end

end