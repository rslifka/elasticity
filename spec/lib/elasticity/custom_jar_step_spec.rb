describe Elasticity::CustomJarStep do

  subject do
    Elasticity::CustomJarStep.new('jar')
  end

  it { should be_a Elasticity::JobFlowStep }

  its(:name) { should == 'Elasticity Custom Jar Step' }
  its(:jar) { should == 'jar' }
  its(:arguments) { should == [] }
  its(:action_on_failure) { should == 'TERMINATE_JOB_FLOW' }

  describe '#to_aws_step' do

    it { should respond_to(:to_aws_step).with(1).argument }

    context 'when there are no arguments provided' do
      let(:cjs_with_no_args) { Elasticity::CustomJarStep.new('jar') }

      it 'should convert to aws step format' do
        cjs_with_no_args.to_aws_step(Elasticity::JobFlow.new('access', 'secret')).should == {
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
        cjs_with_args.to_aws_step(Elasticity::JobFlow.new('access', 'secret')).should == {
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
      Elasticity::CustomJarStep.requires_installation?.should be_false
    end
  end

end