describe Elasticity::GangliaBootstrapAction do

  subject do
    Elasticity::GangliaBootstrapAction.new
  end

  it { should be_a Elasticity::BootstrapAction }

  # its(:name) { should == 'Elasticity Bootstrap Action (Install Ganglia)' }
  # its(:arguments) { should == [] }
  # its(:script) { should == 's3://elasticmapreduce/bootstrap-actions/install-ganglia' }

end
