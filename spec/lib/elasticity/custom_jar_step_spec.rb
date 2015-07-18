describe Elasticity::CustomJarStep do

  subject do
    Elasticity::CustomJarStep.new('jar')
  end

  it { should be_a Elasticity::JobFlowStep }

  describe '.initialize' do
    it 'should set the fields appropriately' do
      expect(subject.name).to eql('Elasticity Custom Jar Step')
      expect(subject.jar).to eql('jar')
      expect(subject.arguments).to eql([])
    end
  end

  describe '#to_aws_step' do

    it { should respond_to(:to_aws_step).with(1).argument }

    context 'when there are no arguments provided' do
      let(:cjs_with_no_args) { Elasticity::CustomJarStep.new('jar') }

      it 'should convert to aws step format' do
        cjs_with_no_args.to_aws_step(Elasticity::JobFlow.new).should == {
          :action_on_failure => 'TERMINATE_JOB_FLOW',
          :hadoop_jar_step => {
            :jar => 'jar'
          },
          :name => 'Elasticity Custom Jar Step'
        }
      end
    end

    context 'when there are arguments provided' do
      let(:cjs_with_args) do
        Elasticity::CustomJarStep.new('jar').tap do |cjs|
          cjs.arguments = ['arg1', 'arg2']
        end
      end

      it 'should convert to aws step format' do
        cjs_with_args.to_aws_step(Elasticity::JobFlow.new).should == {
          :action_on_failure => 'TERMINATE_JOB_FLOW',
          :hadoop_jar_step => {
            :jar => 'jar',
            :args => ['arg1', 'arg2',],
          },
          :name => 'Elasticity Custom Jar Step'
        }
      end
    end

  end

  describe '.requires_installation?' do
    it 'should not require installation' do
      expect(Elasticity::CustomJarStep.requires_installation?).to be false
    end
  end

end