describe Elasticity::SetupHadoopDebuggingStep do

  it 'should be a CustomJarStep' do
    expect(subject).to be_a(Elasticity::CustomJarStep)
  end

  it 'should set the appropriate fields' do
    expect(subject.name).to eql('Elasticity Setup Hadoop Debugging')
    expect(subject.jar).to eql('s3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/script-runner/script-runner.jar')
    expect(subject.arguments).to eql(['s3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/state-pusher/0.1/fetch'])
    expect(subject.action_on_failure).to eql('TERMINATE_JOB_FLOW')
  end

end