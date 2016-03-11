describe Elasticity::HiveStep do

  subject do
    Elasticity::HiveStep.new('script.hql')
  end

  it { should be_a Elasticity::JobFlowStep }

  describe '.initialize' do
    it 'should set the fields appropriately' do
      expect(subject.name).to eql('Elasticity Hive Step (script.hql)')
      expect(subject.script).to eql('script.hql')
      expect(subject.variables).to eql({})
      expect(subject.action_on_failure).to eql('TERMINATE_JOB_FLOW')
    end
  end

  describe '#to_aws_step' do

    it 'should convert to aws step format' do
      step = subject.to_aws_step(Elasticity::JobFlow.new)
      step[:name].should == 'Elasticity Hive Step (script.hql)'
      step[:action_on_failure].should == 'TERMINATE_JOB_FLOW'
      step[:hadoop_jar_step][:jar].should == 's3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/script-runner/script-runner.jar'
      step[:hadoop_jar_step][:args].should start_with([
            's3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/hive/hive-script',
            '--base-path',
            's3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/hive/',
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
        step = hs_with_variables.to_aws_step(Elasticity::JobFlow.new)
        step[:hadoop_jar_step][:args][9..13].should == %w(-d VAR1=VALUE1 -d VAR2=VALUE2)
      end
    end

  end

  describe '.requires_installation?' do
    it 'should require installation' do
      expect(Elasticity::HiveStep.requires_installation?).to be true
    end
  end

  describe '.aws_installation_steps' do

    let(:install_hive_step) do
      {
        :action_on_failure => 'TERMINATE_JOB_FLOW',
        :hadoop_jar_step => {
          :jar => 's3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/script-runner/script-runner.jar',
          :args => [
            's3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/hive/hive-script',
            '--base-path',
            's3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/hive/',
            '--install-hive',
            '--hive-versions',
            'latest'
          ],
        },
        :name => 'Elasticity - Install Hive'
      }
    end

    let(:configure_hive_step) do
      {
        :action_on_failure => 'TERMINATE_JOB_FLOW',
        :hadoop_jar_step => {
          :jar => 's3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/script-runner/script-runner.jar',
          :args => [
            's3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/hive/hive-script',
            '--base-path',
            's3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/hive/',
            '--install-hive-site',
            '--hive-site=s3://TEST/hive-site.xml',
            '--hive-versions',
            'latest'
          ],
        },
        :name => 'Elasticity - Configure Hive via Hive Site'
      }
    end

    context 'when a hive site configuration file is not specified' do
      it 'should specify how to install Hive' do
        Elasticity::HiveStep.aws_installation_steps.should == [install_hive_step]
      end
    end

    context 'when a hive site configuration file is specified' do
      before do
        Elasticity.configure do |config|
          config.hive_site = 's3://TEST/hive-site.xml'
        end
      end
      it 'should specify how to install Hive' do
        Elasticity::HiveStep.aws_installation_steps.should == [install_hive_step, configure_hive_step]
      end
    end

  end

end