describe Elasticity::HadoopBootstrapAction do

  subject do
    Elasticity::HadoopBootstrapAction.new('option', 'value')
  end

  it { should be_a Elasticity::BootstrapAction }

  # its(:name) { should == 'Elasticity Bootstrap Action (Configure Hadoop)' }
  # its(:arguments) { should == %w(option value) }
  # its(:script) { should == 's3n://elasticmapreduce/bootstrap-actions/configure-hadoop' }

end