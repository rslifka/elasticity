describe Elasticity::SparkStep do

  subject do
    Elasticity::SparkStep.new('jar', 'class')
  end

  it { should be_a Elasticity::JobFlowStep }

  describe '.initialize' do
    it 'should set the fields appropriately' do
      expect(subject.name).to eql('Elasticity Spark Step')
      expect(subject.jar).to eql('jar')
      expect(subject.main_class).to eql('class')
      expect(subject.spark_arguments).to eql({})
      expect(subject.app_arguments).to eql({})
      expect(subject.action_on_failure).to eql('TERMINATE_JOB_FLOW')
    end
  end

  describe '#to_aws_step' do

    it { should respond_to(:to_aws_step).with(1).argument }

    context 'when there are no arguments provided' do
      let(:ss_with_no_args) { Elasticity::SparkStep.new('jar', 'class') }

      it 'should convert to aws step format' do
        ss_with_no_args.to_aws_step(Elasticity::JobFlow.new).should == {
          :name => 'Elasticity Spark Step',
          :action_on_failure => 'TERMINATE_JOB_FLOW',
          :hadoop_jar_step => {
            :jar => 'command-runner.jar',
            :args => %w(spark-submit --class class jar)
          }
        }
      end
    end

    context 'when there are arguments provided' do
      let(:ss_with_args) do
        Elasticity::SparkStep.new('jar', 'class').tap do |ss|
          ss.spark_arguments = { 'key1' => 'value1' }
          ss.app_arguments = { 'key2' => 'value2' }
        end
      end

      it 'should convert to aws step format' do
        ss_with_args.to_aws_step(Elasticity::JobFlow.new).should == {
          :name => 'Elasticity Spark Step',
          :action_on_failure => 'TERMINATE_JOB_FLOW',
          :hadoop_jar_step => {
            :jar => 'command-runner.jar',
            :args => %w(spark-submit --class class --key1 value1 jar --key2 value2)
          }
        }
      end
    end

  end

  describe '.requires_installation?' do
    it 'should not require installation' do
      expect(Elasticity::SparkStep.requires_installation?).to be false
    end
  end

end
