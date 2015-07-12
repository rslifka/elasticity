describe Elasticity::ScriptStep do

  subject { Elasticity::ScriptStep.new('script_location', 'arg1', 'arg2') }

  it 'should be a CustomJarStep' do
    expect(subject).to be_a(Elasticity::CustomJarStep)
  end

  it 'should set the appropriate default fields' do
    expect(subject.name).to eql('Elasticity Script Step')
    expect(subject.jar).to eql('s3://elasticmapreduce/libs/script-runner/script-runner.jar')
    expect(subject.arguments).to eql(%w(script_location arg1 arg2))
    expect(subject.action_on_failure).to eql('TERMINATE_JOB_FLOW')
  end

end