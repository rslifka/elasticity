describe Elasticity::BootstrapAction do

  subject do
    Elasticity::BootstrapAction.new('script', 'option', 'value')
  end

  its(:name) { should == 'Elasticity Bootstrap Action' }
  its(:option) { should == 'option' }
  its(:value) { should == 'value' }
  its(:script) { should == 'script' }

  describe '#to_aws_bootstrap_action' do
    it 'should create a bootstrap action' do
      subject.to_aws_bootstrap_action.should ==
        {
          :name => 'Elasticity Bootstrap Action',
          :script_bootstrap_action => {
            :path => 'script',
            :args => %w(option value)
          }
        }
    end
  end

end