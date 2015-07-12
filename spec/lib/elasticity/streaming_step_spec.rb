describe Elasticity::StreamingStep do

  subject do
    Elasticity::StreamingStep.new('INPUT_BUCKET', 'OUTPUT_BUCKET', 'MAPPER', 'REDUCER', '-ARG1', 'VALUE1')
  end

  it { should be_a Elasticity::JobFlowStep }

  describe '.initialize' do
    it 'should set the fields appropriately' do
      expect(subject.name).to eql('Elasticity Streaming Step')
      expect(subject.action_on_failure).to eql('TERMINATE_JOB_FLOW')
      expect(subject.input_bucket).to eql('INPUT_BUCKET')
      expect(subject.output_bucket).to eql('OUTPUT_BUCKET')
      expect(subject.mapper).to eql('MAPPER')
      expect(subject.reducer).to eql('REDUCER')
      expect(subject.arguments).to eql(%w(-ARG1 VALUE1))
    end
  end

  describe '#to_aws_step' do

    it 'should convert to aws step format' do
      subject.to_aws_step(Elasticity::JobFlow.new('_', '_')).should == {
        :name => 'Elasticity Streaming Step',
        :action_on_failure => 'TERMINATE_JOB_FLOW',
        :hadoop_jar_step => {
          :jar => '/home/hadoop/contrib/streaming/hadoop-streaming.jar',
          :args => %w(-input INPUT_BUCKET -output OUTPUT_BUCKET -mapper MAPPER -reducer REDUCER -ARG1 VALUE1),
        },
      }
    end

  end

  describe '.requires_installation?' do
    it 'should not require installation' do
      expect(Elasticity::StreamingStep.requires_installation?).to be false
    end
  end

end
