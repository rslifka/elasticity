describe Elasticity::AwsRequest do

  subject do
    Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_access_key")
  end

  its(:access_key) { should == "aws_access_key_id" }
  its(:secret_key) { should == "aws_secret_access_key" }
  its(:options)    { should == {:secure => true} }

  describe "#sign_params" do
    before do
      Time.stub(:now).and_return(Time.at(1302461096))
    end

    it "should sign according to Amazon's rules" do
      signed_params = subject.send(:sign_params, {}, "GET", "example.com", "/")
      signed_params.should == "AWSAccessKeyId=aws_access_key_id&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=2011-04-10T18%3A44%3A56.000Z&Signature=jVLfPS056dNmjpCcikBnPmRHJNZ8YGaI7zdmHWUk658%3D"
    end
  end

  describe "#aws_emr_request" do
    before do
      Time.stub(:now).and_return(Time.at(1302461096))
    end

    describe "options" do

      context "when no options are specified" do
        it "should use the default option values" do
          RestClient.should_receive(:get).with(/^https:\/\/elasticmapreduce.amazonaws.com/)
          subject.aws_emr_request({})
        end
      end

      context "when :region is specified" do
        let(:region) { "eu-west-1" }
        let(:request) { Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_access_key", :region => region) }

        it "should request against that region" do
          RestClient.should_receive(:get).with(/elasticmapreduce\.#{region}\.amazonaws\.com/)
          request.aws_emr_request({})
        end
      end

      context "when :secure is false" do
        let(:request) { Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_access_key", :secure => false) }

        it "should use the value to determine the request type" do
          RestClient.should_receive(:get).with(/^http:/)
          request.aws_emr_request({})
        end
      end

      context "when :secure is true" do
        let(:request) { Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_access_key", :secure => true) }

        it "should use the value to determine the request type" do
          RestClient.should_receive(:get).with(/^https:/)
          request.aws_emr_request({})
        end
      end
    end
  end

  describe "#==" do
    let(:same_object) { subject }
    let(:same_values) { Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_access_key", {}) }
    let(:diff_type)   { Object.new }

    it { should == same_object }
    it { should == same_values }
    it { should_not == diff_type }

    it "should be false on deep comparison" do
      {
        :@access_key => "_",
        :@secret_key => "_",
        :@options => {:foo => :bar}
      }.each do |variable, value|
        other = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_access_key", {})
        other.instance_variable_set(variable, value)
        subject.should_not == other
      end
    end

  end

  describe ".aws_escape" do
    it "should escape according to Amazon's rules" do
      # Don't encode reserved characters
      Elasticity::AwsRequest.aws_escape("foo-_.~bar").should == "foo-_.~bar"
      # Encode as %20, not as +
      Elasticity::AwsRequest.aws_escape("foo bar").should == "foo%20bar"
      # Percent encode all other characters with %XY, where X and Y are hex characters 0-9 and uppercase A-F.
      Elasticity::AwsRequest.aws_escape("foo$&+,/:;=?@bar").should == "foo%24%26%2B%2C%2F%3A%3B%3D%3F%40bar"
    end
  end

end
