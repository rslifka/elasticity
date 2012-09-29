describe Elasticity::HiveStep do

  subject do
    Elasticity::HiveStep.new('script.hql')
  end

  it { should be_a Elasticity::JobFlowStep }

  its(:name) { should == 'Elasticity Hive Step (script.hql)' }
  its(:script) { should == 'script.hql' }
  its(:variables) { should == {} }
  its(:action_on_failure) { should == 'TERMINATE_JOB_FLOW' }

  describe '#to_aws_step' do

    it 'should convert to aws step format' do
      step = subject.to_aws_step(Elasticity::JobFlow.new('access', 'secret'))
      step[:name].should == 'Elasticity Hive Step (script.hql)'
      step[:action_on_failure].should == 'TERMINATE_JOB_FLOW'
      step[:hadoop_jar_step][:jar].should == 's3://elasticmapreduce/libs/script-runner/script-runner.jar'
      step[:hadoop_jar_step][:args].should start_with([
        's3://elasticmapreduce/libs/hive/hive-script',
        '--base-path',
        's3://elasticmapreduce/libs/hive/',
        '--hive-versions',
        'latest',
        '--run-hive-script',
        '--args',
        '-f',
        'script.hql'
      ])
    end

    context 'when variables are provided' do
      let(:hs_with_variables) do
        Elasticity::HiveStep.new('script.pig').tap do |hs|
          hs.variables = {
            'VAR1' => 'VALUE1',
            'VAR2' => 'VALUE2'
          }
        end
      end

      it 'should convert to aws step format' do
        step = hs_with_variables.to_aws_step(Elasticity::JobFlow.new('access', 'secret'))
        step[:hadoop_jar_step][:args][9..13].should == %w(-d VAR1=VALUE1 -d VAR2=VALUE2)
      end
    end

  end

  describe '.requires_installation?' do
    it 'should require installation' do
      Elasticity::HiveStep.requires_installation?.should be_true
    end
  end

  describe '.aws_installation_step' do

    it 'should provide a means to install Hive' do
      Elasticity::HiveStep.aws_installation_step.should == {
        :action_on_failure => 'TERMINATE_JOB_FLOW',
        :hadoop_jar_step => {
          :jar => 's3://elasticmapreduce/libs/script-runner/script-runner.jar',
          :args => [
            's3://elasticmapreduce/libs/hive/hive-script',
            '--base-path',
            's3://elasticmapreduce/libs/hive/',
            '--install-hive',
            '--hive-versions',
            'latest'
          ],
        },
        :name => 'Elasticity - Install Hive'
      }
    end

  end

end