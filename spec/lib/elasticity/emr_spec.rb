require 'spec_helper'

describe Elasticity::EMR do

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
          aws_request.should_receive(:aws_emr_request).with({"Operation" => "DescribeJobFlows"}).and_return(@describe_jobflows_xml)
          Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
          emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
          xml_result = nil
          emr.describe_jobflows do |xml|
            xml_result = xml
          end
          xml_result.should == @describe_jobflows_xml
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

        context "when a block is given" do
          it "should yield the XML result" do
            aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
            aws_request.should_receive(:aws_emr_request).with({
              "Operation" => "TerminateJobFlows",
              "JobFlowIds.member.1" => "j-1"
            }).and_return(@terminate_jobflows_xml)
            Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
            emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
            xml_result = nil
            emr.terminate_jobflows("j-1") do |xml|
              xml_result = xml
            end
            xml_result.should == @terminate_jobflows_xml
          end
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
        before do
          @modify_instance_groups_xml = <<-RESPONSE
            <ModifyInstanceGroupsResponse xmlns="http://elasticmapreduce.amazonaws.com/doc/2009-03-31">
              <ResponseMetadata>
                <RequestId>4ef75373-659c-11e0-bdf6-e3d62a364c28</RequestId>
              </ResponseMetadata>
            </ModifyInstanceGroupsResponse>
          RESPONSE
        end
        it "should yield the XML result" do
          aws_request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_key")
          aws_request.should_receive(:aws_emr_request).and_return(@modify_instance_groups_xml)
          Elasticity::AwsRequest.should_receive(:new).and_return(aws_request)
          emr = Elasticity::EMR.new("aws_access_key_id", "aws_secret_key")
          xml_result = nil
          emr.modify_instance_groups({"ig-1" => 2})  do |xml|
            xml_result = xml
          end
          xml_result.should == @modify_instance_groups_xml
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

end