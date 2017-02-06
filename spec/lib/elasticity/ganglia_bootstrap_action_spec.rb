describe Elasticity::GangliaBootstrapAction do

  subject do
    Elasticity::GangliaBootstrapAction.new
  end

  it { should be_a Elasticity::BootstrapAction }

  describe '.intialize' do
    it 'should set the fields appropriately' do
      expect(subject.name).to eql('Elasticity Bootstrap Action (Install Ganglia)')
      expect(subject.arguments).to eql([])
      expect(subject.script).to eql('s3://cxar-ato-team/snowplow-hosted-elasticmapreduce/bootstrap-actions/install-ganglia')
    end
  end


end
