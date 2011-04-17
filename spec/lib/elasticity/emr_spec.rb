require 'spec_helper'

describe Elasticity::EMR do

  describe "#add_instance_groups" do

    describe "integration happy path" do

      context "when properly specified" do
        use_vcr_cassette "add_instance_groups/one_group_successful", :record => :none
        it "should add the instance groups" do
          emr = Elasticity::EMR.new(ENV["aws_access_key_id"], ENV["aws_secret_key"])
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
          emr = Elasticity::EMR.new(ENV["aws_access_key_id"], ENV["aws_secret_key"])
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
            {:instance_type=>"m1.small", :instance_role=>"CORE", :market=>"ON_DEMAND", :instance_count=>1, :name=>"Go Canucks Go!", :bid_price=>0},
              {:instance_type=>"m1.small", :instance_role=>"CORE", :market=>"ON_DEMAND", :instance_count=>1, :name=>"Go Canucks Go!", :bid_price=>0},
          ]
          aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
          aws_request.should_receive(:aws_emr_request).with({
            "Operation" => "AddInstanceGroups",
            "InstanceGroups.member.1.Name"=>"Go Canucks Go!",
            "InstanceGroups.member.1.InstanceRole"=>"CORE",
            "InstanceGroups.member.1.InstanceCount"=>1,
            "InstanceGroups.member.1.BidPrice"=>0,
            "InstanceGroups.member.1.InstanceType"=>"m1.small",
            "InstanceGroups.member.1.Market"=>"ON_DEMAND",
            "InstanceGroups.member.2.Name"=>"Go Canucks Go!",
            "InstanceGroups.member.2.InstanceRole"=>"CORE",
            "InstanceGroups.member.2.InstanceCount"=>1,
            "InstanceGroups.member.2.BidPrice"=>0,
            "InstanceGroups.member.2.InstanceType"=>"m1.small",
            "InstanceGroups.member.2.Market"=>"ON_DEMAND",
            "JobFlowId"=>"j-19WDDS68ZUENP"
          })
          Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
          emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
          emr.add_instance_groups("j-19WDDS68ZUENP", instance_group_configs)
        end

        it "should return an array of the instance groups created" do
          aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
          aws_request.should_receive(:aws_emr_request).and_return(@add_instance_groups_xml)
          Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
          emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
          emr.add_instance_groups("", []).should == ["ig-1", "ig-2", "ig-3"]
        end
      end

      context "when a block is provided" do
        it "should yield the XML result" do
          aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
          aws_request.should_receive(:aws_emr_request).and_return("AWS XML")
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

  describe "#describe_jobflows" do

    describe "integration happy path" do
      use_vcr_cassette "describe_jobflows/all_jobflows", :record => :none
      it "should return the names of all running job flows" do
        emr = Elasticity::EMR.new(ENV["aws_access_key_id"], ENV["aws_secret_key"])
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
                    <State>TERMINATED</State>
                  </ExecutionStatusDetail>
                  <JobFlowId>j-p</JobFlowId>
                  <Name>Pig Job</Name>
                </member>
                <member>
                  <ExecutionStatusDetail>
                    <State>TERMINATED</State>
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
        aws_request.should_receive(:aws_emr_request).with({"Operation" => "DescribeJobFlows"}).and_return(@describe_jobflows_xml)
        Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
        emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
        jobflows = emr.describe_jobflows
        jobflows.map(&:name).should == ["Pig Job", "Hive Job"]
      end

      context "when a block is provided" do
        it "should yield the XML result" do
          aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
          aws_request.should_receive(:aws_emr_request).and_return("describe!")
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

  describe "#modify_instance_groups" do

    describe "integration happy path" do
      context "when the instance group exists" do
        use_vcr_cassette "modify_instance_groups/set_instances_to_3", :record => :none
        it "should terminate the specified jobflow" do
          emr = Elasticity::EMR.new(ENV["aws_access_key_id"], ENV["aws_secret_key"])
          instance_group_config = {"ig-2T1HNUO61BG3O" => 2}
          emr.modify_instance_groups(instance_group_config)
        end
      end
    end

    describe "unit tests" do

      context "when the instance group exists" do
        it "should modify the specified instance group" do
          aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
          aws_request.should_receive(:aws_emr_request).with({
            "Operation" => "ModifyInstanceGroups",
            "InstanceGroups.member.1.InstanceGroupId" => "ig-1",
            "InstanceGroups.member.1.InstanceCount" => 2
          })
          Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
          emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
          emr.modify_instance_groups({"ig-1" => 2})
        end
      end

      context "when a block is given" do
        it "should yield the XML result" do
          aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
          aws_request.should_receive(:aws_emr_request).and_return("xml result!")
          Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
          emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
          xml_result = nil
          emr.modify_instance_groups({"ig-1" => 2}) do |xml|
            xml_result = xml
          end
          xml_result.should == "xml result!"
        end
      end


      context "when there is an error" do

        before do
          @error_message = "1 validation error detected: Value null at 'instanceGroups.1.member.instanceCount' failed to satisfy constraint: Member must not be null"
          @error_xml = <<-ERROR
            <ErrorResponse xmlns="http://elasticmapreduce.amazonaws.com/doc/2009-03-31">
              <Error>
                <Message>#{@error_message}</Message>
              </Error>
            </ErrorResponse>
          ERROR
        end

        it "should raise an ArgumentError with the error message" do
          aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
          @exception = RestClient::BadRequest.new
          @exception.should_receive(:http_body).and_return(@error_xml)
          aws_request.should_receive(:aws_emr_request).and_raise(@exception)
          Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
          emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
          lambda {
            emr.modify_instance_groups({"ig-1" => 2})
          }.should raise_error(ArgumentError, @error_message)
        end

      end

    end

  end

  describe "#terminate_jobflows" do

    describe "integration happy path" do
      context "when the job flow exists" do
        use_vcr_cassette "terminate_jobflows/one_jobflow", :record => :none
        it "should terminate the specified jobflow" do
          emr = Elasticity::EMR.new(ENV["aws_access_key_id"], ENV["aws_secret_key"])
          emr.terminate_jobflows("j-1MZ5TVWFJRSKN")
        end
      end
    end

    describe "unit tests" do

      context "when the jobflow exists" do
        before do
          @terminate_jobflows_xml = <<-RESPONSE
            <TerminateJobFlowsResponse xmlns="http://elasticmapreduce.amazonaws.com/doc/2009-03-31">
              <ResponseMetadata>
                <RequestId>2690d7eb-ed86-11dd-9877-6fad448a8419</RequestId>
              </ResponseMetadata>
            </TerminateJobFlowsResponse>
          RESPONSE
        end
        it "should terminate the specific jobflow" do
          aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
          aws_request.should_receive(:aws_emr_request).with({
            "Operation" => "TerminateJobFlows",
            "JobFlowIds.member.1" => "j-1"
          }).and_return(@terminate_jobflows_xml)
          Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
          emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
          emr.terminate_jobflows("j-1")
        end
      end

      context "when the jobflow does not exist" do
        it "should raise an ArgumentError" do
          aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
          aws_request.should_receive(:aws_emr_request).and_raise(RestClient::BadRequest)
          Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
          emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
          lambda {
            emr.terminate_jobflows("invalid_jobflow_id")
          }.should raise_error(ArgumentError)
        end
      end

      context "when a block is given" do
        it "should yield the XML result" do
          aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
          aws_request.should_receive(:aws_emr_request).and_return("terminated!")
          Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
          emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
          xml_result = nil
          emr.terminate_jobflows("j-1") do |xml|
            xml_result = xml
          end
          xml_result.should == "terminated!"
        end
      end

    end
  end

  describe "#direct" do

    describe "integration happy path" do
      use_vcr_cassette "direct/terminate_jobflow", :record => :none
      it "should terminate the specified jobflow" do
        emr = Elasticity::EMR.new(ENV["aws_access_key_id"], ENV["aws_secret_key"])
        params = {
          "Operation" => "TerminateJobFlows",
          "JobFlowIds.member.1" => "j-1MZ5TVWFJRSKN"
        }
        emr.direct(params)
      end
    end

    describe "unit tests" do
      before do
        @terminate_jobflows_xml = <<-RESPONSE
          <TerminateJobFlowsResponse xmlns="http://elasticmapreduce.amazonaws.com/doc/2009-03-31">
            <ResponseMetadata>
              <RequestId>2690d7eb-ed86-11dd-9877-6fad448a8419</RequestId>
            </ResponseMetadata>
          </TerminateJobFlowsResponse>
        RESPONSE
      end
      it "should pass through directly to the request" do
        aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
        aws_request.should_receive(:aws_emr_request).with({
          "Operation" => "TerminateJobFlows",
          "JobFlowIds.member.1" => "j-1"
        }).and_return(@terminate_jobflows_xml)
        Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
        emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
        params = {
          "Operation" => "TerminateJobFlows",
          "JobFlowIds.member.1" => "j-1"
        }
        emr.direct(params).should == @terminate_jobflows_xml
      end
    end
  end

  describe ".convert_ruby_to_aws" do
    it "should convert the params" do
      add_jobflow_steps_params = {
        :job_flow_id => "j-1",
        :steps => [
          {
            :action_on_failure => "CONTINUE",
            :name => "First New Job Step",
            :hadoop_jar_step => {
              :args => ["arg1", "arg2", "arg3",],
              :jar => "first_step.jar",
              :main_class => "first_class.jar"
            }
          },
            {
              :action_on_failure => "CANCEL_AND_WAIT",
              :name => "Second New Job Step",
              :hadoop_jar_step => {
                :args => ["arg4", "arg5", "arg6",],
                :jar => "second_step.jar",
                :main_class => "second_class.jar"
              }
            }
        ]
      }
      expected_result = {
        "JobFlowId" => "j-1",
        "Steps.member.1.Name" => "First New Job Step",
        "Steps.member.1.ActionOnFailure" => "CONTINUE",
        "Steps.member.1.HadoopJarStep.Jar" => "first_step.jar",
        "Steps.member.1.HadoopJarStep.MainClass" => "first_class.jar",
        "Steps.member.1.HadoopJarStep.Args.member.1" => "arg1",
        "Steps.member.1.HadoopJarStep.Args.member.2" => "arg2",
        "Steps.member.1.HadoopJarStep.Args.member.3" => "arg3",
        "Steps.member.2.Name" => "Second New Job Step",
        "Steps.member.2.ActionOnFailure" => "CANCEL_AND_WAIT",
        "Steps.member.2.HadoopJarStep.Jar" => "second_step.jar",
        "Steps.member.2.HadoopJarStep.MainClass" => "second_class.jar",
        "Steps.member.2.HadoopJarStep.Args.member.1" => "arg4",
        "Steps.member.2.HadoopJarStep.Args.member.2" => "arg5",
        "Steps.member.2.HadoopJarStep.Args.member.3" => "arg6"
      }
      Elasticity::EMR.send(:convert_ruby_to_aws, add_jobflow_steps_params).should == expected_result
    end
  end

end