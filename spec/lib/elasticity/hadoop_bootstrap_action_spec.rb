describe Elasticity::HadoopBootstrapAction do

  subject do
    Elasticity::HadoopBootstrapAction.new('option', 'value')
  end

  it { should be_a Elasticity::BootstrapAction }

  describe '.initialize' do
    it 'should set the fields appropriately' do
      expect(subject.name).to eql('Elasticity Bootstrap Action (Configure Hadoop)')
      expect(subject.arguments).to eql(%w(option value))
      expect(subject.script).to eql('s3n://cxar-ato-team/snowplow-hosted-elasticmapreduce/bootstrap-actions/configure-hadoop')
    end
  end


end