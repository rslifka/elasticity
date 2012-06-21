describe 'Elasticity::JobFlow Integration Examples' do

  let(:emr) { double('Elasticity::EMR') }

  before do
    Elasticity::EMR.should_receive(:new).with('access', 'secret').and_return(emr)
  end

  describe 'Hive' do

    let(:hive_step) do
      Elasticity::HiveStep.new('s3n://slif-hive/test.q').tap do |hs|
        hs.variables = {'OUTPUT' => 's3n://slif-test/output'}
        hs.action_on_failure = 'CONTINUE'
      end
    end

    let(:hive_jobflow) do
      Elasticity::JobFlow.new('access', 'secret').tap do |jf|
        jf.log_uri = 's3n://slif-test/output/logs'
        jf.add_step(hive_step)
      end
    end

    it 'should launch the Hive job with the specified EMR credentials' do
      emr.should_receive(:run_job_flow).with({
        :name => 'Elasticity Job Flow',
        :log_uri => 's3n://slif-test/output/logs',
        :instances => {
          :ec2_key_name => 'default',
          :hadoop_version => '0.20',
          :instance_count => 2,
          :master_instance_type => 'm1.small',
          :slave_instance_type => 'm1.small',
        },
        :steps => [
          {
            :action_on_failure => 'TERMINATE_JOB_FLOW',
            :hadoop_jar_step => {
              :jar => 's3://elasticmapreduce/libs/script-runner/script-runner.jar',
              :args => [
                's3://elasticmapreduce/libs/hive/hive-script',
                  '--base-path',
                  's3://elasticmapreduce/libs/hive/',
                  '--install-hive'
              ],
            },
            :name => 'Elasticity - Install Hive'
          },
            {
              :action_on_failure => 'CONTINUE',
              :hadoop_jar_step => {
                :jar => 's3://elasticmapreduce/libs/script-runner/script-runner.jar',
                :args => [
                  's3://elasticmapreduce/libs/hive/hive-script',
                    '--run-hive-script',
                    '--args',
                    '-f', 's3n://slif-hive/test.q',
                    '-d', 'OUTPUT=s3n://slif-test/output'
                ],
              },
              :name => 'Elasticity Hive Step (s3n://slif-hive/test.q)'
            }
        ]
      }).and_return('HIVE_JOBFLOW_ID')

      hive_jobflow.run.should == 'HIVE_JOBFLOW_ID'
    end

  end

end