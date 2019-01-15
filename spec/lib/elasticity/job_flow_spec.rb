describe Elasticity::JobFlow do

  subject do
    Elasticity::JobFlow.new
  end

  describe '.initialize' do
    it 'should set the fields appropriately' do
      expect(subject.action_on_failure).to eql('TERMINATE_JOB_FLOW')
      expect(subject.ec2_key_name).to eql(nil)
      expect(subject.security_configuration).to eql(nil)
      expect(subject.name).to eql('Elasticity Job Flow')
      expect(subject.instance_count).to eql(2)
      expect(subject.log_uri).to eql(nil)
      expect(subject.master_instance_type).to eql('m1.small')
      expect(subject.slave_instance_type).to eql('m1.small')
      expect(subject.ami_version).to eql(nil)
      expect(subject.release_label).to eql(nil)
      expect(subject.aws_applications).to eql([])
      expect(subject.aws_configurations).to eql([])
      expect(subject.keep_job_flow_alive_when_no_steps).to eql(false)
      expect(subject.ec2_subnet_id).to eql(nil)
      expect(subject.placement).to eql('us-east-1a')
      expect(subject.region).to eql('us-east-1')
      expect(subject.visible_to_all_users).to eql(false)
      expect(subject.enable_debugging).to eql(false)
      expect(subject.job_flow_role).to eql(nil)
      expect(subject.service_role).to eql(nil)
      expect(subject.additional_info).to eql(nil)
      expect(subject.jobflow_id).to eql(nil)
      expect(subject.additional_master_security_groups).to eql(nil)
      expect(subject.additional_slave_security_groups).to eql(nil)
      expect(subject.timeout).to eql(60)
    end
  end

  describe '#placement=' do

    context 'when the placement is set' do

      context 'when the placement is valid' do
        before do
          subject.placement = 'us-west-1a'
        end

        it 'should set the region' do
          subject.region.should == 'us-west-1'
        end
      end

      context 'when the placement is not valid' do
        it 'should set the region' do
          expect {
            subject.placement = 'BAD_PLACEMENT'
          }.to raise_error(Elasticity::UnknownPlacementError, "'BAD_PLACEMENT' is not a valid EMR placement")
        end
      end

    end

    context 'when the placement is not set' do
      before do
        subject.placement = nil
      end
      it 'should not modify the region' do
        subject.region.should == 'us-east-1'
      end
    end

  end

  describe '#additional_info=' do
    context 'when set' do
      before do
        subject.additional_info = 'additional info'
      end
      it 'additional_info is a string' do
        expect(subject.additional_info).to eq('additional info')
      end
    end
  end

  describe '#security_configuration=' do
    context 'when set' do
      before do
        subject.security_configuration = 'security configuration'
      end
      it 'security_configuration is a string' do
        expect(subject.security_configuration).to eq('security configuration')
      end
    end
  end


  describe '#enable_debugging=' do

    context 'when a log_uri is present' do
      before do
        subject.log_uri = '_'
      end
      it 'should set enable_debugging' do
        subject.enable_debugging = true
        subject.enable_debugging.should == true
      end
    end

    context 'when a log_uri is not present' do
      before do
        subject.log_uri = nil
      end
      it 'should raise an error' do
        expect {
          subject.enable_debugging = true
        }.to raise_error(Elasticity::LogUriMissingError, 'To enable debugging, please set a #log_uri')
        subject.enable_debugging.should == false
      end
    end

  end

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

  describe '#ec2_subnet_id=' do
    it 'should set ec2_subnet_id' do
      subject.ec2_subnet_id = 'TEST_ID'
      subject.ec2_subnet_id.should == 'TEST_ID'
    end

    it 'should unset placement (which has a default value) because having both set is EMR-invalid' do
      subject.placement = 'us-east-1d'

      subject.ec2_subnet_id = '_'
      subject.placement.should == nil
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
        Elasticity::EMR.any_instance.stub(:run_job_flow => '_')
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

  describe '#add_configuration' do
    let(:configuration) { {'Classification' => 'spark'} }
    context 'when the jobflow is not yet started' do
      it 'should not raise an error' do
        expect {
          subject.add_bootstrap_action(configuration)
        }.to_not raise_error
      end
    end

    context 'when the jobflow is already started' do
      before do
        Elasticity::EMR.any_instance.stub(:run_job_flow => '_')
        subject.add_step(Elasticity::CustomJarStep.new('_'))
        subject.run
      end
      it 'should raise an error' do
        expect {
          subject.add_configuration(configuration)
        }.to raise_error(Elasticity::JobFlowRunningError, 'To add configurations, please create a new job flow.')
      end
    end

  end

  describe '#add_step' do

    context 'when the jobflow is already running' do

      let(:emr) { double('Elasticity::EMR', :run_job_flow => 'RUNNING_JOBFLOW_ID') }

      let(:running_jobflow) do
        Elasticity::JobFlow.new.tap do |jf|
          jf.add_step(Elasticity::PigStep.new('_'))
        end
      end

      before do
        Elasticity::EMR.stub(:new).and_return(emr)
        running_jobflow.run
      end

      context 'when the step requires installation' do

        context 'when the installation has already happened' do
          let(:additional_step) { Elasticity::PigStep.new('_') }

          it 'should submit the step' do
            emr.should_receive(:add_jobflow_steps).with('RUNNING_JOBFLOW_ID', [additional_step.to_aws_step(running_jobflow)])
            running_jobflow.add_step(additional_step)
          end
        end

        context 'when the installation has not yet happened' do
          let(:additional_step) { Elasticity::HiveStep.new('_') }

          it 'should submit the installation step and the step' do
            emr.should_receive(:add_jobflow_steps).with('RUNNING_JOBFLOW_ID', Elasticity::HiveStep.aws_installation_steps << additional_step.to_aws_step(running_jobflow))
            running_jobflow.add_step(additional_step)
          end
        end

      end

      context 'when the step does not require installation' do

        let(:additional_step) { Elasticity::CustomJarStep.new('jar') }

        it 'should submit the step' do
          emr.should_receive(:add_jobflow_steps).with('RUNNING_JOBFLOW_ID', [additional_step.to_aws_step(running_jobflow)])
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
        Elasticity::JobFlow.new.tap do |jobflow|
          jobflow_steps.each { |s| jobflow.add_step(s) }
        end
      end
      let(:aws_steps) do
        [
          Elasticity::HiveStep.aws_installation_steps,
          jobflow_steps[0].to_aws_step(jobflow_with_steps),
          Elasticity::PigStep.aws_installation_steps,
          jobflow_steps[1].to_aws_step(jobflow_with_steps),
          jobflow_steps[2].to_aws_step(jobflow_with_steps),
        ].flatten
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

      context 'when debugging is enabled' do
        before do
          jobflow_with_steps.log_uri = '_'
          jobflow_with_steps.enable_debugging = true
          aws_steps.insert(0, Elasticity::SetupHadoopDebuggingStep.new('us-east-1').to_aws_step(jobflow_with_steps))
        end
        it 'should incorporate the step to setup Hadoop debugging' do
          jobflow_with_steps.send(:jobflow_config).should be_a_hash_including({:steps => aws_steps})
        end
      end

    end

    describe 'log URI' do

      context 'when a log URI is specified' do
        let(:jobflow_with_log_uri) do
          Elasticity::JobFlow.new.tap do |jf|
            jf.log_uri = 'LOG_URI'
          end
        end
        it 'should incorporate it into the jobflow config' do
          jobflow_with_log_uri.send(:jobflow_config).should be_a_hash_including({:log_uri => 'LOG_URI'})
        end
      end

      context 'when a log URI is not specified' do
        let(:jobflow_with_no_log_uri) do
          Elasticity::JobFlow.new.tap do |jf|
            jf.log_uri = nil
          end
        end
        it 'should not make space for it in the jobflow config' do
          jobflow_with_no_log_uri.send(:jobflow_config).should_not have_key(:log_uri)
        end
      end

    end

    describe 'tags' do

      context 'when a tag is specified' do
        let(:jobflow_with_tags) do
          Elasticity::JobFlow.new.tap do |jf|
            jf.tags = {
              name: 'app-name',
              contact: 'admin@example.com'
            }
          end
        end
        it 'should incorporate it into the jobflow config' do
          jobflow_with_tags.send(:jobflow_config).should be_a_hash_including(
            tags: [
              {
                key: 'name',
                value: 'app-name'
              }, {
                key: 'contact',
                value: 'admin@example.com'
              }
            ]
          )
        end
      end

      context 'when a tag is not specified' do
        let(:jobflow_with_no_tags) do
          Elasticity::JobFlow.new.tap do |jf|
            jf.tags = nil
          end
        end
        it 'should not make space for it in the jobflow config' do
          jobflow_with_no_tags.send(:jobflow_config).should_not have_key(:tags)
        end
      end

    end

    describe 'job flow role' do

      context 'when a job flow role is specified' do
        let(:jobflow_with_job_flow_role) do
          Elasticity::JobFlow.new.tap do |jf|
            jf.job_flow_role = 'JOB_FLOW_ROLE'
          end
        end
        it 'should incorporate it into the jobflow config' do
          jobflow_with_job_flow_role.send(:jobflow_config).should be_a_hash_including({:job_flow_role => 'JOB_FLOW_ROLE'})
        end
      end

      context 'when a job flow role is not specified' do
        let(:jobflow_with_no_job_flow_role) do
          Elasticity::JobFlow.new.tap do |jf|
            jf.job_flow_role = nil
          end
        end
        it 'should not make space for it in the jobflow config' do
          jobflow_with_no_job_flow_role.send(:jobflow_config).should_not have_key(:job_flow_role)
        end
      end

    end

    describe 'service role' do

      context 'when a service role is specified' do
        let(:jobflow_with_service_role) do
          Elasticity::JobFlow.new.tap do |jf|
            jf.service_role = 'SERVICE_ROLE'
          end
        end
        it 'should incorporate it into the jobflow config' do
          jobflow_with_service_role.send(:jobflow_config).should be_a_hash_including({:service_role => 'SERVICE_ROLE'})
        end
      end

      context 'when a service role is not specified' do
        let(:jobflow_with_no_service_role) do
          Elasticity::JobFlow.new.tap do |jf|
            jf.service_role = nil
          end
        end
        it 'should not make space for it in the jobflow config' do
          jobflow_with_no_service_role.send(:jobflow_config).should_not have_key(:service_role)
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
          Elasticity::JobFlow.new.tap do |jf|
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

    describe 'aws_applications' do
      let(:application) { Elasticity::Application.new({}) }
      let(:emr) { double(Elasticity::EMR, run_job_flow: true) }

      before do
        subject.stub(:emr).and_return(emr)
      end

      context 'with applications' do
        context 'no release_label' do
          it 'fails' do
            subject.instance_variable_set(:@aws_applications, [application])
            expect { subject.run }.to raise_error(RuntimeError, 'Please set the EMR release_label')
          end
        end

        context 'ami_version set' do
          it 'fails' do
            subject.instance_variable_set(:@aws_applications, [application])
            subject.instance_variable_set(:@ami_version, 'latest')
            expect { subject.run }.to raise_error(RuntimeError, 'Please use an EMR release_label not ami_version')
          end
        end

        context 'release_label set' do
          it 'succeeds' do
            subject.instance_variable_set(:@aws_applications, [application])
            subject.instance_variable_set(:@release_label, '4.0.0')
            subject.run
            expect(subject.send(:jobflow_config)[:release_label]).to eql('4.0.0')
          end
        end
      end

      context 'with no applications' do
        it 'sets default ami version and config doesn\'t contain applications' do
          subject.run
          config = subject.send(:jobflow_config)
          expect(config[:ami_version]).to eql('latest')
          expect(config[:applications]).to eql(nil)
        end
      end
    end

    describe 'aws_configurations' do
      let(:configuration) {
        { 'Classification' => 'spark',
          'Properties' => { 'prop' => 'valule'} }
      }

      let(:emr) { double(Elasticity::EMR, run_job_flow: true) }

      before do
        subject.stub(:emr).and_return(emr)
      end

      context 'with configurations' do
        it 'sets the configurations as a part of its config' do
          subject.instance_variable_set(:@aws_configurations, [configuration])
          config = subject.send(:jobflow_config)
          expect(config[:configurations]).to eql([configuration])
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
        :visible_to_all_users => false,
        :instances => {
          :keep_job_flow_alive_when_no_steps => false,
          :instance_groups => ['INSTANCE_GROUP_CONFIGURATION'],
          :placement => {
            :availability_zone => 'us-east-1a'
          }
        }
      }
    end

    before do
      subject.stub(:jobflow_instance_groups).and_return(['INSTANCE_GROUP_CONFIGURATION'])
    end

    it 'should create a jobflow configuration section' do
      subject.send(:jobflow_preamble).should == basic_preamble
    end

    context 'when a key name is provided' do
      it 'should include it in the preamble' do
        subject.ec2_key_name = 'default'
        subject.send(:jobflow_preamble)[:instances].should be_a_hash_including({:ec2_key_name => 'default'})
      end
    end

    context 'when a VPC subnet ID is specified' do
      before do
        subject.ec2_subnet_id = 'subnet-118b9d79'
      end
      it 'should include it in the preamble' do
        subject.send(:jobflow_preamble)[:instances].should be_a_hash_including({:ec2_subnet_id => 'subnet-118b9d79'})
      end
      it 'should not include the placement since a subnet implies a placement' do
        subject.send(:jobflow_preamble)[:instances].should_not include(:placement)
      end
    end

    context 'when jobflow visibility is modified' do
      it 'should be reflected in the jobflow settings' do
        subject.visible_to_all_users = true
        subject.send(:jobflow_preamble).should be_a_hash_including({:visible_to_all_users => true})
      end
    end

    context 'when additional master security groups is provided' do
      it 'should include it in the preamble' do
        subject.additional_master_security_groups = ['group1', 'group2']
        subject.send(:jobflow_preamble)[:instances].should be_a_hash_including({:additional_master_security_groups => ['group1', 'group2']})
      end
    end

    context 'when additional slave security groups is provided' do
      it 'should include it in the preamble' do
        subject.additional_slave_security_groups = ['group1', 'group2']
        subject.send(:jobflow_preamble)[:instances].should be_a_hash_including({:additional_slave_security_groups => ['group1', 'group2']})
      end
    end
  end

  describe '#run' do

    context 'when there are steps added' do
      let(:jobflow_with_steps) do
        Elasticity::JobFlow.new.tap do |jf|
          jf.add_step(Elasticity::CustomJarStep.new('_'))
        end
      end

      context 'when the jobflow has not yet been run' do
        let(:emr) { double('Elasticity::EMR', :run_job_flow => 'JOBFLOW_ID') }

        it 'should run the job with the supplied EMR credentials' do
          Elasticity::EMR.stub(:new).with(:region => 'us-east-1', :timeout => 60).and_return(emr)
          emr.should_receive(:run_job_flow)
          jobflow_with_steps.run
        end

        it 'should run the job with the jobflow config' do
          Elasticity::EMR.stub(:new).and_return(emr)
          jobflow_with_steps.stub(:jobflow_config).and_return('JOBFLOW_CONFIG')
          emr.should_receive(:run_job_flow).with('JOBFLOW_CONFIG')
          jobflow_with_steps.run
        end

        it 'should return the jobflow ID' do
          Elasticity::EMR.stub(:new).and_return(emr)
          expect(jobflow_with_steps.run).to eq('JOBFLOW_ID')
          expect(jobflow_with_steps.jobflow_id).to eq('JOBFLOW_ID')
        end

      end

      context 'when the jobflow has already been run' do
        before do
          Elasticity::EMR.any_instance.stub(:run_job_flow => '_')
          jobflow_with_steps.run
        end
        it 'should raise an error' do
          expect {
            jobflow_with_steps.run
          }.to raise_error(Elasticity::JobFlowRunningError, 'Cannot run a job flow multiple times.  To do more with this job flow, please use #add_step.')
        end
      end

    end

  end

  describe '#cluster_status' do

    context 'before the jobflow has been run' do
      it 'should raise an error' do
        expect {
          subject.cluster_status
        }.to raise_error(Elasticity::JobFlowNotStartedError, 'Please #run this job flow before attempting to retrieve status.')
      end
    end

    context 'after the jobflow has been run' do
      let(:emr) { double('Elasticity::EMR', :run_job_flow => 'JOBFLOW_ID') }
      let(:running_jobflow) { Elasticity::JobFlow.new }
      let(:aws_cluster_status) { JSON.parse('{ "Cluster": { "Status": { "State": "TERMINATED" } } }') }

      before do
        Elasticity::EMR.stub(:new).and_return(emr)
        running_jobflow.add_step(Elasticity::CustomJarStep.new('_'))
        running_jobflow.run
      end

      it 'should return the AWS status' do
        emr.should_receive(:describe_cluster).with('JOBFLOW_ID').and_return(aws_cluster_status)
        Elasticity::ClusterStatus.should_receive(:from_aws_data).with(aws_cluster_status).and_return(build(:cluster_status))

        status = running_jobflow.cluster_status
        expect(status).to be_a(Elasticity::ClusterStatus)
        expect(status.state).to eql('TERMINATED')
      end
    end

  end

  describe '#cluster_step_status' do

    context 'before the jobflow has been run' do
      it 'should raise an error' do
        expect {
          subject.cluster_step_status
        }.to raise_error(Elasticity::JobFlowNotStartedError, 'Please #run this job flow before attempting to retrieve status.')
      end
    end

    context 'after the jobflow has been run' do
      let(:emr) { double('Elasticity::EMR', :run_job_flow => 'JOBFLOW_ID') }
      let(:running_jobflow) { Elasticity::JobFlow.new }

      before do
        Elasticity::EMR.stub(:new).and_return(emr)
        running_jobflow.add_step(Elasticity::CustomJarStep.new('_'))
        running_jobflow.run
      end

      it 'should return the AWS status' do
        emr.should_receive(:list_steps).with('JOBFLOW_ID').and_return('AWS_CLUSTER_STATUS')
        Elasticity::ClusterStepStatus.should_receive(:from_aws_list_data).with('AWS_CLUSTER_STATUS').and_return([build(:cluster_step_status)])

        status = running_jobflow.cluster_step_status
        status.each do |s|
          expect(s).to be_a(Elasticity::ClusterStepStatus)
        end
        expect(status[0].state).to eql('COMPLETED')
      end
    end

  end

  describe '#shutdown' do

    context 'when the jobflow has not yet been started' do
      let(:unstarted_job_flow) { Elasticity::JobFlow.new }
      it 'should be an error' do
        expect {
          unstarted_job_flow.shutdown
        }.to raise_error(Elasticity::JobFlowNotStartedError, 'Cannot #shutdown a job flow that has not yet been #run.')
      end
    end

    context 'when the jobflow has been started' do
      let(:emr) { double('Elasticity::EMR', :run_job_flow => 'JOBFLOW_ID') }
      let(:running_jobflow) { Elasticity::JobFlow.new }
      before do
        Elasticity::EMR.stub(:new).and_return(emr)
        running_jobflow.add_step(Elasticity::CustomJarStep.new('_'))
        running_jobflow.run
      end
      it 'should shutdown the running jobflow' do
        emr.should_receive(:terminate_jobflows).with(['JOBFLOW_ID'])
        running_jobflow.shutdown
      end
    end

  end

  describe '#wait_for_completion' do
    let(:client_block) { Proc.new {} }
    let(:fake_looper) { double(:looper, :go => nil) }

    it 'should kick off a looper' do
      Elasticity::Looper.should_receive(:new).with(subject.method(:retry_check), client_block).and_return(fake_looper)
      fake_looper.should_receive(:go)
      subject.wait_for_completion(&client_block)
    end
  end

  describe '#retry_check' do

    context 'when the jobflow is active' do
      let(:jobflow_status) { double(:active? => true) }
      before do
        subject.stub(:cluster_status).and_return(jobflow_status)
      end
      it 'returns true and the result of #status' do
        subject.send(:retry_check).should == [true, jobflow_status]
      end
    end

    context 'when the jobflow is not active' do
      let(:jobflow_status) { double(:active? => false) }
      before do
        subject.stub(:cluster_status).and_return(jobflow_status)
      end
      it 'returns true and the result of #status' do
        subject.send(:retry_check).should == [false, jobflow_status]
      end
    end

  end

  describe '.from_jobflow_id' do

    before do
      Elasticity::JobFlow.any_instance.stub(:cluster_step_status).and_return([])
    end

    let(:jobflow) { Elasticity::JobFlow.from_jobflow_id('JOBFLOW_ID') }

    describe 'creating a jobflow with the specified credentials' do

      context 'when the region is not specified' do
        it 'should use the default of us-east-1a' do
          j = Elasticity::JobFlow.from_jobflow_id('_')
          j.send(:emr).should == Elasticity::EMR.new(:region => 'us-east-1')
        end
      end

      context 'when the region is specified' do
        it 'should use the specified region' do
          j = Elasticity::JobFlow.from_jobflow_id('_', 'us-west-1')
          j.send(:emr).should == Elasticity::EMR.new(:region => 'us-west-1')
        end
      end

    end

    it 'should create a jobflow' do
      jobflow.should be_a Elasticity::JobFlow
    end

    it 'should create a running jobflow' do
      jobflow.send(:is_jobflow_running?).should == true
    end

    it 'should remember the jobflow ID' do
      jobflow.instance_variable_get(:@jobflow_id).should == 'JOBFLOW_ID'
    end

    context 'when no steps have been installed' do
      before do
        Elasticity::JobFlow.any_instance.should_receive(:cluster_step_status).and_return([])
      end
      it 'should show that no steps are installed' do
        jobflow.instance_variable_get(:@installed_steps).should == []
      end
    end

    context 'when steps have been installed do' do
      before do
        Elasticity::JobFlow.any_instance.should_receive(:cluster_step_status).and_return([
          build(:cluster_step_status, :name => Elasticity::PigStep.aws_installation_step_name),
          build(:cluster_step_status, :name => Elasticity::HiveStep.aws_installation_step_name)
          ])
      end
      it 'should show that no steps are installed' do
        jobflow.instance_variable_get(:@installed_steps).should =~ [Elasticity::PigStep, Elasticity::HiveStep]
      end
    end

  end
end
