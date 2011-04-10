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
        it "should terminate the specific jobflow" do
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

end