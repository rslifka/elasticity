describe Elasticity::ScriptStep do

  subject do
    Elasticity::ScriptStep.new('script_location', 'arg1', 'arg2')
  end

  it { should be_a Elasticity::CustomJarStep }

  describe '.initialize' do
    it 'should set the fields appropriately' do
      expect(subject.name).to eql('Elasticity Script Step')
      expect(subject.jar).to eql('s3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/script-runner/script-runner.jar')
      expect(subject.arguments).to eql(%w(script_location arg1 arg2))
    end
  end

end