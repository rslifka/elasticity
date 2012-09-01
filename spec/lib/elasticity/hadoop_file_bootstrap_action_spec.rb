describe Elasticity::HadoopFileBootstrapAction do

  subject do
    Elasticity::HadoopFileBootstrapAction.new('config_file')
  end

  it { should be_a Elasticity::BootstrapAction }

  its(:name) { should == 'Elasticity Bootstrap Action (Configure Hadoop via File)' }
  its(:option) { should == '--mapred-config-file' }
  its(:value) { should == 'config_file' }
  its(:script) { should == 's3n://elasticmapreduce/bootstrap-actions/configure-hadoop' }

end