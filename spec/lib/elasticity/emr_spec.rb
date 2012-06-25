describe Elasticity::EMR do

  subject do
    Elasticity::EMR.new(AWS_ACCESS_KEY_ID, AWS_SECRET_KEY)
  end

  its(:aws_request) { should == Elasticity::AwsRequest.new(AWS_ACCESS_KEY_ID, AWS_SECRET_KEY, {}) }

  describe "#add_instance_groups" do

    describe "integration happy path" do

      context "when properly specified" do
        use_vcr_cassette "add_instance_groups/one_group_successful", :record => :none
        it "should add the instance groups" do
          emr = Elasticity::EMR.new(AWS_ACCESS_KEY_ID, AWS_SECRET_KEY)
          instance_group_config = {
            :instance_count => 1,
            :instance_role => "TASK",
            :instance_type => "m1.small",
            :market => "ON_DEMAND",
            :name => "Go Canucks Go!"
          }
          instance_group_ids = emr.add_instance_groups("j-OALI7TZTQMHX", [instance_group_config])
          instance_group_ids.should == ["ig-2GOVEN6HVJZID"]
        end
      end

      context "when improperly specified" do
        use_vcr_cassette "add_instance_groups/one_group_unsuccessful", :record => :none
        it "should add the instance groups" do
          emr = Elasticity::EMR.new(AWS_ACCESS_KEY_ID, AWS_SECRET_KEY)
          instance_group_config = {
            :bid_price => 0,
            :instance_count => 1,
            :instance_role => "TASK",
            :instance_type => "m1.small",
            :market => "ON_DEMAND",
            :name => "Go Canucks Go!"
          }
          lambda {
            emr.add_instance_groups("j-19WDDS68ZUENP", [instance_group_config])
          }.should raise_error(ArgumentError, "Task instance group already exists in the job flow, cannot add more task groups")
        end
      end

    end

    describe "unit tests" do

      context "when multiple instance groups are specified" do
        before do
          @add_instance_groups_xml = <<-ADD_GROUPS
            <AddInstanceGroupsResponse xmlns="http://elasticmapreduce.amazonaws.com/doc/2009-03-31">
              <AddInstanceGroupsResult>
                <JobFlowId>j-OALI7TZTQMHX</JobFlowId>
                <InstanceGroupIds>
                  <member>ig-1</member>
                  <member>ig-2</member>
                  <member>ig-3</member>
                </InstanceGroupIds>
              </AddInstanceGroupsResult>
            </AddInstanceGroupsResponse>
          ADD_GROUPS
        end

        it "should iterate over them and send the correct params to AWS" do
          instance_group_configs = [
            {:instance_type => "m1.small", :instance_role => "CORE", :market => "ON_DEMAND", :instance_count => 1, :name => "Go Canucks Go!", :bid_price => 0},
              {:instance_type => "m1.small", :instance_role => "CORE", :market => "ON_DEMAND", :instance_count => 1, :name => "Go Canucks Go!", :bid_price => 0},
          ]
          aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
          aws_request.should_receive(:submit).with({:operation => "AddInstanceGroups", :job_flow_id => "j-19WDDS68ZUENP", :instance_groups => [{:instance_type => "m1.small", :instance_role => "CORE", :market => "ON_DEMAND", :instance_count => 1, :name => "Go Canucks Go!", :bid_price => 0}, {:instance_type => "m1.small", :instance_role => "CORE", :market => "ON_DEMAND", :instance_count => 1, :name => "Go Canucks Go!", :bid_price => 0}]})
          Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
          emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
          emr.add_instance_groups("j-19WDDS68ZUENP", instance_group_configs)
        end

        it "should return an array of the instance groups created" do
          aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
          aws_request.should_receive(:submit).and_return(@add_instance_groups_xml)
          Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
          emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
          emr.add_instance_groups("", []).should == ["ig-1", "ig-2", "ig-3"]
        end
      end

      context "when a block is provided" do
        it "should yield the XML result" do
          aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
          aws_request.should_receive(:submit).and_return("AWS XML")
          Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
          emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
          xml_result = nil
          emr.add_instance_groups("", []) do |xml|
            xml_result = xml
          end
          xml_result.should == "AWS XML"
        end
      end

    end

  end

  describe "#add_jobflow_steps" do

    describe "integration happy path" do
      use_vcr_cassette "add_jobflow_steps/add_multiple_steps", :record => :none

      before do
        @setup_pig_step = {
          :action_on_failure => "TERMINATE_JOB_FLOW",
          :hadoop_jar_step => {
            :args => [
              "s3://elasticmapreduce/libs/pig/pig-script",
                "--base-path",
                "s3://elasticmapreduce/libs/pig/",
                "--install-pig"
            ],
            :jar => "s3://elasticmapreduce/libs/script-runner/script-runner.jar"
          },
          :name => "Setup Pig"
        }
        @emr = Elasticity::EMR.new(AWS_ACCESS_KEY_ID, AWS_SECRET_KEY)
        @jobflow_id = @emr.run_job_flow({
          :name => "Elasticity Test Flow (EMR Pig Script)",
          :instances => {
            :ec2_key_name => "sharethrough-dev",
            :instance_count => 2,
            :master_instance_type => "m1.small",
            :slave_instance_type => "m1.small",
          },
          :steps => [@setup_pig_step]
        })
      end

      it "should add a job flow step to the specified job flow" do
        @emr.add_jobflow_steps(@jobflow_id, {
          :steps => [
            @setup_pig_step.merge(:name => "Setup Pig 2"),
              @setup_pig_step.merge(:name => "Setup Pig 3")
          ]
        })
        jobflow = @emr.describe_jobflows.select { |jf| jf.jobflow_id = @jobflow_id }.first
        jobflow.steps.map(&:name).should == ["Setup Pig", "Setup Pig 2", "Setup Pig 3"]
      end

    end

    describe "unit tests" do

      it "should add the specified steps to the job flow" do
        aws_request = Elasticity::AwsRequest.new(AWS_ACCESS_KEY_ID, AWS_SECRET_KEY)
        aws_request.should_receive(:submit).with({:operation => "AddJobFlowSteps", :job_flow_id => "j-1", :steps => [{:action_on_failure => "TERMINATE_JOB_FLOW", :name => "Step 1", :hadoop_jar_step => {:args => ["arg1-1", "arg1-2"], :jar => "jar1"}}, {:action_on_failure => "CONTINUE", :name => "Step 2", :hadoop_jar_step => {:args => ["arg2-1", "arg2-2"], :jar => "jar2"}}]})
        Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
        emr = Elasticity::EMR.new(AWS_ACCESS_KEY_ID, AWS_SECRET_KEY)
        emr.add_jobflow_steps("j-1", {
          :steps => [
            {
              :action_on_failure => "TERMINATE_JOB_FLOW",
              :name => "Step 1",
              :hadoop_jar_step => {
                :args => ["arg1-1", "arg1-2"],
                :jar => "jar1",
              }
            },
              {
                :action_on_failure => "CONTINUE",
                :name => "Step 2",
                :hadoop_jar_step => {
                  :args => ["arg2-1", "arg2-2"],
                  :jar => "jar2",
                }
              }
          ]
        })
      end

      context "when a block is given" do
        it "should yield the XML result" do
          aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
          aws_request.should_receive(:submit).and_return("xml_response")
          Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
          emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
          xml_result = nil
          emr.add_jobflow_steps("", {}) do |xml|
            xml_result = xml
          end
          xml_result.should == "xml_response"
        end
      end

    end

  end

  describe "#describe_jobflows" do

    describe "integration happy path" do
      use_vcr_cassette "describe_jobflows/all_jobflows", :record => :none
      it "should return the names of all running job flows" do
        emr = Elasticity::EMR.new(AWS_ACCESS_KEY_ID, AWS_SECRET_KEY)
        jobflows = emr.describe_jobflows
        jobflows.map(&:name).should == ["WM+RS", "Interactive Audience Hive Test", "Audience (Hive)", "Audience Reporting"]
        jobflows.map(&:jobflow_id).should == ["j-1MZ5TVWFJRSKN", "j-38EU2XZQP9KJ4", "j-2TDCVGEEHOFI9", "j-NKKQ429D858I"]
        jobflows.map(&:state).should == ["TERMINATED", "TERMINATED", "TERMINATED", "TERMINATED"]
      end
    end

    describe "unit tests" do
      before do
        @describe_jobflows_xml = <<-JOBFLOWS
          <DescribeJobFlowsResponse xmlns="http://elasticmapreduce.amazonaws.com/doc/2009-03-31">
            <DescribeJobFlowsResult>
              <JobFlows>
                <member>
                  <ExecutionStatusDetail>
                    <CreationDateTime>2011-04-04T17:41:51Z</CreationDateTime>
                    <State>TERMINATED</State>
                  </ExecutionStatusDetail>
                  <JobFlowId>j-p</JobFlowId>
                  <Name>Pig Job</Name>
                </member>
                <member>
                  <ExecutionStatusDetail>
                    <State>TERMINATED</State>
                    <CreationDateTime>2011-04-04T17:41:51Z</CreationDateTime>
                  </ExecutionStatusDetail>
                  <JobFlowId>j-h</JobFlowId>
                  <Name>Hive Job</Name>
                </member>
              </JobFlows>
            </DescribeJobFlowsResult>
          </DescribeJobFlowsResponse>
        JOBFLOWS
      end

      it "should return the names of all running job flows" do
        aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
        aws_request.should_receive(:submit).with({:operation => "DescribeJobFlows"}).and_return(@describe_jobflows_xml)
        Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
        emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
        jobflows = emr.describe_jobflows
        jobflows.map(&:name).should == ["Pig Job", "Hive Job"]
      end

      it "should accept additional parameters" do
        aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
        aws_request.should_receive(:submit).with({:CreatedBefore => "2011-10-04", :operation => "DescribeJobFlows"}).and_return(@describe_jobflows_xml)
        Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
        emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
        emr.describe_jobflows(:CreatedBefore => "2011-10-04")
      end

      context "when a block is provided" do
        it "should yield the XML result" do
          aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
          aws_request.should_receive(:submit).and_return("describe!")
          Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
          emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
          xml_result = nil
          emr.describe_jobflows do |xml|
            xml_result = xml
          end
          xml_result.should == "describe!"
        end
      end
    end

  end

  describe "#describe_jobflow" do
    before do
      @describe_jobflows_xml = <<-JOBFLOWS
        <DescribeJobFlowsResponse xmlns="http://elasticmapreduce.amazonaws.com/doc/2009-03-31">
          <DescribeJobFlowsResult>
            <JobFlows>
              <member>
                <ExecutionStatusDetail>
                  <State>TERMINATED</State>
                  <CreationDateTime>2011-04-04T17:41:51Z</CreationDateTime>
                </ExecutionStatusDetail>
                <JobFlowId>j-3UN6WX5RRO2AG</JobFlowId>
                <Name>The One Job Flow</Name>
              </member>
            </JobFlows>
          </DescribeJobFlowsResult>
        </DescribeJobFlowsResponse>
      JOBFLOWS
    end

    it "should ask AWS about the specified job flow" do
      aws_request = Elasticity::AwsRequest.new("", "")
      aws_request.should_receive(:submit).with({:operation => "DescribeJobFlows", :job_flow_ids => ["j-3UN6WX5RRO2AG"]})
      Elasticity::AwsRequest.stub(:new).and_return(aws_request)
      emr = Elasticity::EMR.new("", "")
      emr.describe_jobflow("j-3UN6WX5RRO2AG")
    end

    context "when the job flow ID exists" do
      it "should return a JobFlow" do
        aws_request = Elasticity::AwsRequest.new("", "")
        aws_request.stub(:submit).with({:operation => "DescribeJobFlows", :job_flow_ids => ["j-3UN6WX5RRO2AG"]}).and_return(@describe_jobflows_xml)
        Elasticity::AwsRequest.stub(:new).and_return(aws_request)
        emr = Elasticity::EMR.new("", "")
        jobflow = emr.describe_jobflow("j-3UN6WX5RRO2AG")
        jobflow.jobflow_id.should == "j-3UN6WX5RRO2AG"
      end
    end

    context "when a block is provided" do
      it "should yield to the block" do
        aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
        aws_request.should_receive(:submit).and_return("describe!")
        Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
        emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
        xml_result = nil
        emr.describe_jobflow("_") do |xml|
          xml_result = xml
        end
        xml_result.should == "describe!"
      end
    end
  end

  describe "#modify_instance_groups" do

    describe "integration happy path" do
      context "when the instance group exists" do
        use_vcr_cassette "modify_instance_groups/set_instances_to_3", :record => :none
        it "should terminate the specified jobflow" do
          emr = Elasticity::EMR.new(AWS_ACCESS_KEY_ID, AWS_SECRET_KEY)
          instance_group_config = {"ig-2T1HNUO61BG3O" => 2}
          emr.modify_instance_groups(instance_group_config)
        end
      end
    end

    describe "unit tests" do

      context "when the instance group exists" do
        it "should modify the specified instance group" do
          aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
          aws_request.should_receive(:submit).with({:operation => "ModifyInstanceGroups", :instance_groups => [{:instance_group_id => "ig-1", :instance_count => 2}]})
          Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
          emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
          emr.modify_instance_groups({"ig-1" => 2})
        end
      end

      context "when a block is given" do
        it "should yield the XML result" do
          aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
          aws_request.should_receive(:submit).and_return("xml result!")
          Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
          emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
          xml_result = nil
          emr.modify_instance_groups({"ig-1" => 2}) do |xml|
            xml_result = xml
          end
          xml_result.should == "xml result!"
        end
      end

    end

  end

  describe '#run_jobflow' do

    it 'should start the specified job flow' do
      Elasticity::AwsRequest.any_instance.should_receive(:submit).with({
        :operation => 'RunJobFlow',
        :jobflow_params => '_'
      })
      subject.run_job_flow({:jobflow_params => '_'})
    end

    describe 'jobflow response handling' do
      let(:jobflow_xml_response) do
        <<-XML
          <RunJobFlowResponse xmlns="http://elasticmapreduce.amazonaws.com/doc/2009-03-31">
            <RunJobFlowResult>
              <JobFlowId>j-G6N5HA528AD4</JobFlowId>
            </RunJobFlowResult>
            <ResponseMetadata>
              <RequestId>b22f4aea-6a4b-11e0-9ddc-a168e244afdb</RequestId>
            </ResponseMetadata>
          </RunJobFlowResponse>
        XML
      end

      it 'should return the ID of the running job flow' do
        Elasticity::AwsRequest.any_instance.should_receive(:submit).and_return(jobflow_xml_response)
        subject.run_job_flow({}).should == 'j-G6N5HA528AD4'
      end
    end

    context 'when a block is given' do
      let(:result) { '_' }
      it 'should yield the submission results' do
        Elasticity::AwsRequest.any_instance.should_receive(:submit).and_return(result)
        subject.run_job_flow({}) do |xml|
          xml.should == '_'
        end
      end
    end

  end

  describe '#terminate_jobflows' do

    it 'should terminate the specific jobflow' do
      Elasticity::AwsRequest.any_instance.should_receive(:submit).with({
        :operation => 'TerminateJobFlows',
        :job_flow_ids => ['j-1']
      })
      subject.terminate_jobflows('j-1')
    end

    context 'when a block is given' do
      let(:result) { '_' }
      it 'should yield the termination results' do
        Elasticity::AwsRequest.any_instance.should_receive(:submit).and_return(result)
        subject.terminate_jobflows('j-1') do |xml|
          xml.should == '_'
        end
      end
    end

  end

  describe '#set_termination_protection' do

    context 'when protection is enabled' do
      it 'should enable protection on the specified jobflows' do
        Elasticity::AwsRequest.any_instance.should_receive(:submit).with({
          :operation => 'SetTerminationProtection',
          :termination_protected => true,
          :job_flow_ids => ['jobflow1', 'jobflow2']
        })
        subject.set_termination_protection(['jobflow1', 'jobflow2'], true)
      end
    end

    context 'when protection is disabled' do
      it 'should disable protection on the specified jobflows' do
        Elasticity::AwsRequest.any_instance.should_receive(:submit).with({
          :operation => 'SetTerminationProtection',
          :termination_protected => false,
          :job_flow_ids => ['jobflow1', 'jobflow2']
        })
        subject.set_termination_protection(['jobflow1', 'jobflow2'], false)
      end
    end

    context 'when protection is not specified' do
      it 'should enable protection on the specified jobflows' do
        Elasticity::AwsRequest.any_instance.should_receive(:submit).with({
          :operation => 'SetTerminationProtection',
          :termination_protected => true,
          :job_flow_ids => ['jobflow1', 'jobflow2']
        })
        subject.set_termination_protection(['jobflow1', 'jobflow2'])
      end
    end

    context 'when a block is given' do
      let(:result) { '_' }
      it 'should yield the termination results' do
        Elasticity::AwsRequest.any_instance.should_receive(:submit).and_return(result)
        subject.set_termination_protection([]) do |xml|
          xml.should == '_'
        end
      end
    end

  end

  describe '#direct' do
    let(:params) { {:foo => 'bar'} }

    it 'should pass through directly to the request and return the results of the request' do
      Elasticity::AwsRequest.any_instance.should_receive(:submit).with(params).and_return('RESULT')
      subject.direct(params).should == 'RESULT'
    end
  end

  describe '#==' do
    let(:same_object) { subject }
    let(:same_values) { Elasticity::EMR.new(AWS_ACCESS_KEY_ID, AWS_SECRET_KEY) }
    let(:diff_type) { Object.new }

    it { should == same_object }
    it { should == same_values }
    it { should_not == diff_type }

    it 'should be false on deep comparison' do
      other = Elasticity::EMR.new(AWS_ACCESS_KEY_ID, AWS_SECRET_KEY)
      other.instance_variable_set(:@aws_request, Elasticity::AwsRequest.new('_', '_'))
      subject.should_not == other
    end
  end

end
