require 'spec_helper'

describe Elasticity::AwsRequest do

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

  describe "#sign_params" do
    before do
      Time.should_receive(:now).and_return(Time.at(1302461096))
    end
    it "should sign according to Amazon's rules" do
      request = Elasticity::AwsRequest.new("aws_access_key_id", "aws_secret_access_key")
      signed_params = request.send(:sign_params, {}, "GET", "example.com", "/")
      signed_params.should == "AWSAccessKeyId=aws_access_key_id&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=2011-04-10T18%3A44%3A56.000Z&Signature=jVLfPS056dNmjpCcikBnPmRHJNZ8YGaI7zdmHWUk658%3D"
    end
  end

end