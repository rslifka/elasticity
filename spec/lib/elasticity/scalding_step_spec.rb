describe Elasticity::ScaldingStep do

  subject do
    Elasticity::ScaldingStep.new('jar', 'class', { 'key' => 'value' })
  end

  it { should be_a Elasticity::JobFlowStep }

  describe '.initialize' do
    it 'should set the fields appropriately' do
      expect(subject.name).to eql('Elasticity Scalding Step')
      expect(subject.action_on_failure).to eql('TERMINATE_JOB_FLOW')
      expect(subject.jar).to eql('jar')
      expect(subject.arguments).to eql(['class', '--hdfs', '--key', 'value'])
    end
  end

  describe '#to_aws_step' do

    it { should respond_to(:to_aws_step).with(1).argument }

    it 'should convert to aws step format' do
      subject.to_aws_step(Elasticity::JobFlow.new).should == {
        :name => 'Elasticity Scalding Step',
        :action_on_failure => 'TERMINATE_JOB_FLOW',
        :hadoop_jar_step => {
          :jar => 'jar',
          :args => %w(class --hdfs --key value)
        }
      }
    end
  end

  describe '.requires_installation?' do
    it 'should not require installation' do
      expect(Elasticity::ScaldingStep.requires_installation?).to be false
    end
  end

end
