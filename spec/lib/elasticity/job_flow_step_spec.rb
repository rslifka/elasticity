describe Elasticity::JobFlowStep do

  class FakeStep
    include Elasticity::JobFlowStep
  end

  describe '.requires_installation?' do
    it 'should be false by default' do
      FakeStep.requires_installation?.should be_false
    end
  end

  describe '.aws_installation_step' do
    it 'should raise an error by default' do
      expect {
        FakeStep.aws_installation_step
      }.to raise_error(RuntimeError, '.aws_installation_step is required to be defined when a step requires installation (e.g. Pig, Hive).')
    end
  end

end