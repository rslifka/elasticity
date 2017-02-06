describe Elasticity::HadoopFileBootstrapAction do

  subject do
    Elasticity::HadoopFileBootstrapAction.new('config_file')
  end

  it { should be_a Elasticity::BootstrapAction }

  describe '.initialize' do
    it 'should set the fields appropriately' do
      expect(subject.name).to eql('Elasticity Bootstrap Action (Configure Hadoop via File)')
      expect(subject.arguments).to eql(%w(--mapred-config-file config_file))
      expect(subject.script).to eql('s3n://cxar-ato-team/snowplow-hosted-elasticmapreduce/bootstrap-actions/configure-hadoop')
    end
  end

end