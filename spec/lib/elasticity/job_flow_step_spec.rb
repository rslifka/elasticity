describe Elasticity::JobFlowStep do

  class FakeStep
    include Elasticity::JobFlowStep
  end

  subject { FakeStep.new }

  describe '#to_aws_step' do

    it 'should take a job flow as context' do
      subject.should respond_to(:to_aws_step).with(1).argument
    end

    it 'should raise an error by default' do
      expect {
        subject.to_aws_step(nil)
      }.to raise_error(RuntimeError, '#to_aws_step is required to be defined on all job flow steps.')
    end

  end

  describe '#requires_installation?' do
    it 'should delegate to the class method' do
      FakeStep.should_receive(:requires_installation?).and_return(true)
      subject.requires_installation?.should == true
    end
  end

  describe '.requires_installation?' do
    it 'should be false by default' do
      expect(FakeStep.requires_installation?).to be false
    end
  end

  describe '#aws_installation_step_name' do
    it 'should delegate to the class method' do
      FakeStep.should_receive(:aws_installation_step_name).and_return('AWS_INSTALLATION_STEP_NAME')
      subject.aws_installation_step_name.should == 'AWS_INSTALLATION_STEP_NAME'
    end
  end

  describe '.aws_installation_step_name' do
    it 'should raise an error by default' do
      expect {
        FakeStep.aws_installation_step_name
      }.to raise_error(RuntimeError, '.aws_installation_step_name is required to be defined when a step requires installation (e.g. Pig, Hive).')
    end
  end

  describe '#aws_installation_steps' do
    it 'should delegate to the class method' do
      FakeStep.should_receive(:aws_installation_steps).and_return('AWS_INSTALLATION_STEPS')
      subject.aws_installation_steps.should == 'AWS_INSTALLATION_STEPS'
    end
  end

  describe '.aws_installation_steps' do
    it 'should raise an error by default' do
      expect {
        FakeStep.aws_installation_steps
      }.to raise_error(RuntimeError, '.aws_installation_step is required to be defined when a step requires installation (e.g. Pig, Hive).')
    end
  end

  describe '.steps_requiring_installation' do
    it 'should list all of the steps requiring installation' do
      Elasticity::JobFlowStep.steps_requiring_installation.should =~ [Elasticity::PigStep, Elasticity::HiveStep]
    end
  end

end