describe 'Elasticity::JobFlow Integration Examples' do

  let(:emr) { double('Elasticity::EMR') }

  before do
    Elasticity::EMR.should_receive(:new).with(:region => 'us-west-1').and_return(emr)
  end

  describe 'Hive' do

    let(:hive_step) do
      Elasticity::HiveStep.new('s3n://slif-hive/test.q').tap do |hs|
        hs.variables = {'OUTPUT' => 's3n://slif-test/output'}
        hs.action_on_failure = 'CONTINUE'
      end
    end

    let(:hive_jobflow) do
      Elasticity::JobFlow.new.tap do |jf|
        jf.placement = 'us-west-1a'
        jf.log_uri = 's3n://slif-test/output/logs'
        jf.add_step(hive_step)
      end
    end

    it 'should launch the Hive job with the specified EMR credentials' do
      emr.should_receive(:run_job_flow).with({
        :name => 'Elasticity Job Flow',
        :log_uri => 's3n://slif-test/output/logs',
        :ami_version => 'latest',
        :visible_to_all_users => false,
        :instances => {
          :keep_job_flow_alive_when_no_steps => false,
          :instance_groups => [
            {
              :instance_count => 1,
              :instance_role => 'MASTER',
              :instance_type => 'm1.small',
              :market => 'ON_DEMAND',
            },
              {
                :instance_count => 1,
                :instance_role => 'CORE',
                :instance_type => 'm1.small',
                :market => 'ON_DEMAND'
              },
          ],
          :placement => {
            :availability_zone => 'us-west-1a'
          },
        },
        :steps => [
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
          },
            {
              :action_on_failure => 'CONTINUE',
              :hadoop_jar_step => {
                :jar => 's3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/script-runner/script-runner.jar',
                :args => [
                  's3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/hive/hive-script',
                  '--base-path',
                  's3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/hive/',
                  '--hive-versions',
                  'latest',
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

  describe 'Pig' do

    let(:pig_step) do
      Elasticity::PigStep.new('s3n://slif-pig-test/test.pig').tap do |ps|
        ps.variables = {'OUTPUT' => 's3n://slif-pig-test/output', 'XREFS' => 's3n://slif-pig-test/xrefs'}
        ps.action_on_failure = 'CONTINUE'
      end
    end

    let(:pig_jobflow) do
      Elasticity::JobFlow.new.tap do |jf|
        jf.placement = 'us-west-1c'
        jf.instance_count = 8
        jf.slave_instance_type = 'm1.xlarge'
        jf.log_uri = 's3n://slif-test/output/logs'
        jf.add_step(pig_step)
      end
    end

    it 'should launch the Pig job with the specified EMR credentials' do
      emr.should_receive(:run_job_flow).with({
        :name => 'Elasticity Job Flow',
        :log_uri => 's3n://slif-test/output/logs',
        :ami_version => 'latest',
        :visible_to_all_users => false,
        :instances => {
          :keep_job_flow_alive_when_no_steps => false,
          :instance_groups => [
            {
              :instance_count => 1,
              :instance_role => 'MASTER',
              :instance_type => 'm1.small',
              :market => 'ON_DEMAND',
            },
              {
                :instance_count => 7,
                :instance_role => 'CORE',
                :instance_type => 'm1.xlarge',
                :market => 'ON_DEMAND'
              },
          ],
          :placement => {
            :availability_zone => 'us-west-1c'
          },
        },

        :steps => [
          {
            :action_on_failure => 'TERMINATE_JOB_FLOW',
            :hadoop_jar_step => {
              :jar => 's3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/script-runner/script-runner.jar',
              :args => [
                's3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/pig/pig-script',
                  '--base-path',
                  's3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/pig/',
                  '--install-pig'
              ],
            },
            :name => 'Elasticity - Install Pig'
          },
            {
              :action_on_failure => 'CONTINUE',
              :hadoop_jar_step => {
                :jar => 's3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/script-runner/script-runner.jar',
                :args => [
                  's3://cxar-ato-team/snowplow-hosted-elasticmapreduce/libs/pig/pig-script',
                    '--run-pig-script',
                    '--args',
                    '-p', 'OUTPUT=s3n://slif-pig-test/output',
                    '-p', 'XREFS=s3n://slif-pig-test/xrefs',
                    '-p', 'E_PARALLELS=26',
                    's3n://slif-pig-test/test.pig'
                ],
              },
              :name => 'Elasticity Pig Step (s3n://slif-pig-test/test.pig)'
            }
        ]
      }).and_return('PIG_JOBFLOW_ID')

      pig_jobflow.run.should == 'PIG_JOBFLOW_ID'
    end

  end

  describe 'Custom Jar' do

    let(:custom_jar_step) do
      Elasticity::CustomJarStep.new('s3n://cxar-ato-team/snowplow-hosted-elasticmapreduce/samples/cloudburst/cloudburst.jar').tap do |cj|
        cj.arguments = [
          's3n://cxar-ato-team/snowplow-hosted-elasticmapreduce/samples/cloudburst/input/s_suis.br',
            's3n://cxar-ato-team/snowplow-hosted-elasticmapreduce/samples/cloudburst/input/100k.br',
            's3n://slif_hadoop_test/cloudburst/output/2011-12-09',
        ]
        cj.action_on_failure = 'TERMINATE_JOB_FLOW'
      end
    end

    let(:custom_jar_jobflow) do
      Elasticity::JobFlow.new.tap do |jf|
        jf.placement = 'us-west-1b'
        jf.log_uri = 's3n://slif-test/output/logs'
        jf.add_step(custom_jar_step)
      end
    end

    it 'should launch the Custom Jar job with the specified EMR credentials' do
      emr.should_receive(:run_job_flow).with({
        :name => 'Elasticity Job Flow',
        :log_uri => 's3n://slif-test/output/logs',
        :ami_version => 'latest',
        :visible_to_all_users => false,
        :instances => {
          :keep_job_flow_alive_when_no_steps => false,
          :instance_groups => [
            {
              :instance_count => 1,
              :instance_role => 'MASTER',
              :instance_type => 'm1.small',
              :market => 'ON_DEMAND',
            },
              {
                :instance_count => 1,
                :instance_role => 'CORE',
                :instance_type => 'm1.small',
                :market => 'ON_DEMAND'
              },
          ],
          :placement => {
            :availability_zone => 'us-west-1b'
          },
        },
        :steps => [
          {
            :action_on_failure => 'TERMINATE_JOB_FLOW',
            :hadoop_jar_step => {
              :jar => 's3n://cxar-ato-team/snowplow-hosted-elasticmapreduce/samples/cloudburst/cloudburst.jar',
              :args => [
                's3n://cxar-ato-team/snowplow-hosted-elasticmapreduce/samples/cloudburst/input/s_suis.br',
                  's3n://cxar-ato-team/snowplow-hosted-elasticmapreduce/samples/cloudburst/input/100k.br',
                  's3n://slif_hadoop_test/cloudburst/output/2011-12-09',
              ],
            },
            :name => 'Elasticity Custom Jar Step'
          }
        ]
      }).and_return('CUSTOM_JAR_JOBFLOW_ID')

      custom_jar_jobflow.run.should == 'CUSTOM_JAR_JOBFLOW_ID'
    end

  end

end