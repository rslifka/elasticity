describe Elasticity::JobFlow do

  before do
    # Ensure we don't accidentally submit to EMR for all of these examples
    Elasticity::EMR.stub(:new).and_return(double('Elasticity::EMR', :run_job_flow => '_'))
  end

  subject do
    Elasticity::JobFlow.new('access', 'secret')
  end

  its(:action_on_failure) { should == 'TERMINATE_JOB_FLOW' }
  its(:ec2_key_name) { should == 'default' }
  its(:hadoop_version) { should == '0.20.205' }
  its(:instance_count) { should == 2 }
  its(:log_uri) { should == nil }
  its(:master_instance_type) { should == 'm1.small' }
  its(:name) { should == 'Elasticity Job Flow' }
  its(:slave_instance_type) { should == 'm1.small' }
  its(:ami_version) { should == 'latest' }
  its(:keep_job_flow_alive_when_no_steps) { should == false }

  describe '#instance_count=' do

    context 'when set to more than 1' do

      it 'should set the number of instances' do
        subject.instance_count = 10
        subject.instance_count.should == 10
      end

      it 'should set the CORE group instance count to COUNT-1 instances' do
        instance_group = Elasticity::InstanceGroup.new
        instance_group.count = 4
        instance_group.role = 'CORE'

        subject.instance_count = 5
        subject.send(:jobflow_instance_groups).should be_include(instance_group.to_aws_instance_config)
      end

    end

    context 'when set to less than 2' do

      it 'should be an error and not set the instance count' do
        subject.instance_count = 10
        expect {
          subject.instance_count = 1
        }.to raise_error(ArgumentError, 'Instance count cannot be set to less than 2 (requested 1)')
        subject.instance_count.should == 10
      end

    end

  end

  describe '#master_instance_type=' do

    it 'should set the master_instance_type' do
      subject.master_instance_type = '_'
      subject.master_instance_type.should == '_'
    end

    it 'should set the MASTER group instance type' do
      instance_group = Elasticity::InstanceGroup.new
      instance_group.type = 'c1.medium'
      instance_group.role = 'MASTER'

      subject.master_instance_type = 'c1.medium'
      subject.send(:jobflow_instance_groups).should be_include(instance_group.to_aws_instance_config)
    end

  end

  describe '#slave_instance_type=' do

    it 'should set the slave_instance_type' do
      subject.slave_instance_type = '_'
      subject.slave_instance_type.should == '_'
    end

    it 'should set the CORE group instance type' do
      instance_group = Elasticity::InstanceGroup.new
      instance_group.type = 'c1.medium'
      instance_group.role = 'CORE'

      subject.slave_instance_type = 'c1.medium'
      subject.send(:jobflow_instance_groups).should be_include(instance_group.to_aws_instance_config)
    end

  end

  describe '#add_bootstrap_action' do

    context 'when the jobflow is not yet started' do
      it 'should not raise an error' do
        expect {
          subject.add_bootstrap_action(nil)
        }.to_not raise_error
      end
    end

    context 'when the jobflow is already started' do
      before do
        subject.add_step(Elasticity::CustomJarStep.new('_'))
        subject.run
      end
      it 'should raise an error' do
        expect {
          subject.add_bootstrap_action(nil)
        }.to raise_error(Elasticity::JobFlowRunningError, 'To modify bootstrap actions, please create a new job flow.')
      end
    end

  end

  describe '#add_step' do

    context 'when the jobflow is already running' do

      let(:emr) { double('Elasticity::EMR', :run_job_flow => 'RUNNING_JOBFLOW_ID') }

      let(:running_jobflow) do
        Elasticity::JobFlow.new('access', 'secret').tap do |jf|
          jf.add_step(Elasticity::PigStep.new('_'))
        end
      end

      before do
        Elasticity::EMR.should_receive(:new).with('access', 'secret').and_return(emr)
        running_jobflow.run
      end

      context 'when the step requires installation' do

        context 'when the installation has already happened' do
          let(:additional_step) { Elasticity::PigStep.new('_') }

          it 'should submit the step' do
            emr.should_receive(:add_jobflow_steps).with('RUNNING_JOBFLOW_ID', {
              :steps => [additional_step.to_aws_step(running_jobflow)]
            })
            running_jobflow.add_step(additional_step)
          end
        end

        context 'when the installation has not yet happened' do
          let(:additional_step) { Elasticity::HiveStep.new('_') }

          it 'should submit the installation step and the step' do
            emr.should_receive(:add_jobflow_steps).with('RUNNING_JOBFLOW_ID', {
              :steps => [
                Elasticity::HiveStep.aws_installation_step,
                  additional_step.to_aws_step(running_jobflow)
              ]
            })
            running_jobflow.add_step(additional_step)
          end
        end

      end

      context 'when the step does not require installation' do

        let(:additional_step) { Elasticity::CustomJarStep.new('jar') }

        it 'should submit the step' do
          emr.should_receive(:add_jobflow_steps).with('RUNNING_JOBFLOW_ID', {
            :steps => [additional_step.to_aws_step(running_jobflow)]
          })
          running_jobflow.add_step(additional_step)
        end

      end

    end

    context 'when the jobflow is not yet running' do
      # This behaviour is tested in #jobflow_config
    end
  end

  describe '#jobflow_config' do

    it 'should incorporate the job flow preamble' do
      subject.stub(:jobflow_preamble).and_return({:preamble => 'PREAMBLE'})
      subject.send(:jobflow_config).should be_a_hash_including({:preamble => 'PREAMBLE'})
    end

    describe 'steps' do

      let(:jobflow_steps) { [Elasticity::HiveStep.new('script.hql'), Elasticity::PigStep.new('script.pig'), Elasticity::CustomJarStep.new('script.jar')] }
      let(:jobflow_with_steps) do
        Elasticity::JobFlow.new('_', '_').tap do |jobflow|
          jobflow_steps.each { |s| jobflow.add_step(s) }
        end
      end
      let(:aws_steps) do
        [
          Elasticity::HiveStep.aws_installation_step,
            jobflow_steps[0].to_aws_step(jobflow_with_steps),
            Elasticity::PigStep.aws_installation_step,
            jobflow_steps[1].to_aws_step(jobflow_with_steps),
            jobflow_steps[2].to_aws_step(jobflow_with_steps),
        ]
      end

      it 'should incorporate the installation and run steps into the jobflow config' do
        jobflow_with_steps.send(:jobflow_config).should be_a_hash_including({:steps => aws_steps})
      end

      context 'when there are more than one installable step of the same type' do
        before do
          jobflow_steps << Elasticity::HiveStep.new('script.hql')
          aws_steps << jobflow_steps.last.to_aws_step(jobflow_with_steps)
        end
        it 'should not include the installation step more than once' do
          jobflow_with_steps.send(:jobflow_config).should be_a_hash_including({:steps => aws_steps})
        end
      end

    end

    describe 'log URI' do

      context 'when a log URI is specified' do
        let(:jobflow_with_log_uri) do
          Elasticity::JobFlow.new('_', '_').tap do |jf|
            jf.log_uri = 'LOG_URI'
          end
        end
        it 'should incorporate it into the jobflow config' do
          jobflow_with_log_uri.send(:jobflow_config).should be_a_hash_including({:log_uri => 'LOG_URI'})
        end
      end

      context 'when a log URI is not specified' do
        let(:jobflow_with_no_log_uri) do
          Elasticity::JobFlow.new('_', '_').tap do |jf|
            jf.log_uri = nil
          end
        end
        it 'should not make space for it in the jobflow config' do
          jobflow_with_no_log_uri.send(:jobflow_config).should_not have_key(:log_uri)
        end
      end

    end

    describe 'bootstrap actions' do

      context 'when bootstrap actions are specified' do
        let(:hadoop_bootstrap_actions) do
          [
            Elasticity::HadoopBootstrapAction.new('OPTION1', 'VALUE1'),
              Elasticity::HadoopBootstrapAction.new('OPTION1', 'VALUE2'),
              Elasticity::HadoopBootstrapAction.new('OPTION2', 'VALUE3')
          ]
        end
        let(:jobflow_with_bootstrap_actions) do
          Elasticity::JobFlow.new('_', '_').tap do |jf|
            hadoop_bootstrap_actions.each do |action|
              jf.add_bootstrap_action(action)
            end
          end
        end
        it 'should include them in the jobflow config' do
          bootstrap_actions = hadoop_bootstrap_actions.map { |a| a.to_aws_bootstrap_action }
          jobflow_with_bootstrap_actions.send(:jobflow_config).should be_a_hash_including({
            :bootstrap_actions => bootstrap_actions
          })
        end
      end

      context 'when bootstrap actions are not specified' do
        it 'should not make space for them in the jobflow config' do
          subject.send(:jobflow_config).should_not have_key(:bootstrap_actions)
        end
      end

    end

  end

  describe '#jobflow_instance_groups' do

    describe 'default instance groups' do

      let(:default_instance_groups) do
        [
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
        ]
      end

      it 'should create a properly specified instance group config' do
        subject.send(:jobflow_instance_groups).should == default_instance_groups
      end

    end

    context 'when a task instance group is specified' do

      let(:task_instance_group) do
        Elasticity::InstanceGroup.new.tap do |i|
          i.count = 2
          i.type = 'c1.medium'
        end
      end

      let(:task_instance_group_config) do
        {
          :instance_count => 2,
          :instance_role => 'TASK',
          :instance_type => 'c1.medium',
          :market => 'ON_DEMAND'
        }
      end

      it 'should include it in the group config' do
        subject.set_task_instance_group(task_instance_group)
        subject.send(:jobflow_instance_groups).should be_include(task_instance_group_config)
      end

    end
  end

  describe '#jobflow_preamble' do

    let(:basic_preamble) do
      {
        :name => 'Elasticity Job Flow',
        :ami_version => 'latest',
        :instances => {
          :keep_job_flow_alive_when_no_steps => false,
          :ec2_key_name => 'default',
          :hadoop_version => '0.20.205',
          :instance_groups => ['INSTANCE_GROUP_CONFIGURATION']
        }
      }
    end

    before do
      subject.stub(:jobflow_instance_groups).and_return(['INSTANCE_GROUP_CONFIGURATION'])
    end

    it 'should create a jobflow configuration section' do
      subject.send(:jobflow_preamble).should == basic_preamble
    end

    context 'when a VPC subnet ID is specified' do
      it 'should include it in the preamble' do
        subject.ec2_subnet_id = 'subnet-118b9d79'
        subject.send(:jobflow_preamble).should be_a_hash_including({:ec2_subnet_id => 'subnet-118b9d79'})
      end
    end

  end

  describe '#run' do

    context 'when there are steps added' do
      let(:jobflow_with_steps) do
        Elasticity::JobFlow.new('STEP_TEST_ACCESS', 'STEP_TEST_SECRET').tap do |jf|
          jf.add_step(Elasticity::CustomJarStep.new('_'))
        end
      end

      context 'when the jobflow has not yet been run' do
        let(:emr) { double('Elasticity::EMR', :run_job_flow => 'JOBFLOW_ID') }

        it 'should run the job with the supplied EMR credentials' do
          Elasticity::EMR.should_receive(:new).with('STEP_TEST_ACCESS', 'STEP_TEST_SECRET').and_return(emr)
          emr.should_receive(:run_job_flow)
          jobflow_with_steps.run
        end

        it 'should run the job with the jobflow config' do
          Elasticity::EMR.stub(:new).with('STEP_TEST_ACCESS', 'STEP_TEST_SECRET').and_return(emr)
          jobflow_with_steps.stub(:jobflow_config).and_return('JOBFLOW_CONFIG')
          emr.should_receive(:run_job_flow).with('JOBFLOW_CONFIG')
          jobflow_with_steps.run
        end

        it 'should return the jobflow ID' do
          Elasticity::EMR.stub(:new).with('STEP_TEST_ACCESS', 'STEP_TEST_SECRET').and_return(emr)
          jobflow_with_steps.run.should == 'JOBFLOW_ID'
        end

      end

      context 'when the jobflow has already been run' do
        before do
          jobflow_with_steps.run
        end
        it 'should raise an error' do
          expect {
            jobflow_with_steps.run
          }.to raise_error(Elasticity::JobFlowRunningError, 'Cannot run a job flow multiple times.  To do more with this job flow, please use #add_step.')
        end
      end

    end

    context 'when there are no steps added' do
      let(:jobflow_with_no_steps) { Elasticity::JobFlow.new('_', '_') }
      it 'should raise an error' do
        expect {
          jobflow_with_no_steps.run
        }.to raise_error(Elasticity::JobFlowMissingStepsError, 'Cannot run a job flow without adding steps.  Please use #add_step.')
      end
    end

  end

  describe '#status' do

    context 'before the jobflow has been run' do
      it 'should raise an error' do
        expect {
          subject.status
        }.to raise_error(Elasticity::JobFlowNotStartedError, 'Please #run this job flow before attempting to retrieve status.')
      end
    end

    context 'after the jobflow has been run' do
      let(:emr) { double('Elasticity::EMR', :run_job_flow => 'JOBFLOW_ID') }
      let(:running_jobflow) { Elasticity::JobFlow.new('_', '_') }
      let(:jobflow_status) do
        Elasticity::JobFlowStatus.new.tap do |js|
          js.stub(:state => 'TERMINATED')
        end
      end
      before do
        Elasticity::EMR.stub(:new).and_return(emr)
        running_jobflow.add_step(Elasticity::CustomJarStep.new('_'))
        running_jobflow.run
      end
      it 'should return the AWS status' do
        emr.should_receive(:describe_jobflow).with('JOBFLOW_ID').and_return(jobflow_status)
        status = running_jobflow.status
        status.should be_a(Elasticity::JobFlowStatus)
        status.state.should == 'TERMINATED'
      end
    end

  end

  describe '#shutdown' do

    context 'when the jobflow has not yet been started' do
      let(:unstarted_job_flow) { Elasticity::JobFlow.new('_', '_') }
      it 'should be an error' do
        expect {
          unstarted_job_flow.shutdown
        }.to raise_error(Elasticity::JobFlowNotStartedError, 'Cannot #shutdown a job flow that has not yet been #run.')
      end
    end

    context 'when the jobflow has been started' do
      let(:emr) { double('Elasticity::EMR', :run_job_flow => 'JOBFLOW_ID') }
      let(:running_jobflow) { Elasticity::JobFlow.new('_', '_') }
      before do
        Elasticity::EMR.stub(:new).and_return(emr)
        running_jobflow.add_step(Elasticity::CustomJarStep.new('_'))
        running_jobflow.run
      end
      it 'should shutdown the running jobflow' do
        emr.should_receive(:terminate_jobflows).with('JOBFLOW_ID')
        running_jobflow.shutdown
      end
    end

  end

end