describe Elasticity::HadoopBootstrapAction do

  subject do
    Elasticity::HadoopBootstrapAction.new('option', 'value')
  end

  its(:name) { should == 'Elasticity Bootstrap Action (Configure Hadoop)' }
  its(:option) { should == 'option' }
  its(:value) { should == 'value' }

  describe '#to_aws_bootstrap_action' do

    it 'should create a bootstrap action' do
      subject.to_aws_bootstrap_action.should ==
        {
          :name => 'Elasticity Bootstrap Action (Configure Hadoop)',
          :script_bootstrap_action => {
            :path => 's3n://elasticmapreduce/bootstrap-actions/configure-hadoop',
            :args => ['option', 'value']
          }
        }
    end

  end

end