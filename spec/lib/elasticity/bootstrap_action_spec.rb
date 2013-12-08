describe Elasticity::BootstrapAction do

  subject do
    Elasticity::BootstrapAction.new('script', 'option', 'value')
  end

  its(:name) { should == 'Elasticity Bootstrap Action' }
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

  describe 'deprecation: @option' do
    let(:bootstrap_action) { Elasticity::BootstrapAction.new('script', 'option', 'value') }

    describe '#initialize' do
      it 'should initialize properly' do
        expect(bootstrap_action.option).to eq('option')
        expect(bootstrap_action.args[0]).to eq('option')
      end
    end

    describe '#option=' do
      before do
        bootstrap_action.stub(:warn)
      end

      it 'should be deprecated' do
        expect(bootstrap_action).to receive(:warn).with('[DEPRECATION] `@option` is deprecated, please use @args instead.')
        bootstrap_action.option = '_'
      end

      it 'should set @option' do
        bootstrap_action.option = 'foo'
        expect(bootstrap_action.option).to eq('foo')
      end

      it 'should set @args[0]' do
        bootstrap_action.option = 'foo'
        expect(bootstrap_action.args[0]).to eq('foo')
      end
    end
  end

  describe 'deprecation: @value' do
    let(:bootstrap_action) { Elasticity::BootstrapAction.new('script', 'option', 'value') }

    describe '#initialize' do
      it 'should initialize properly' do
        expect(bootstrap_action.value).to eq('value')
        expect(bootstrap_action.args[1]).to eq('value')
      end
    end

    describe '#option=' do
      before do
        bootstrap_action.stub(:warn)
      end

      it 'should be deprecated' do
        expect(bootstrap_action).to receive(:warn).with('[DEPRECATION] `@value` is deprecated, please use @args instead.')
        bootstrap_action.value = '_'
      end

      it 'should set @option' do
        bootstrap_action.value = 'foo'
        expect(bootstrap_action.value).to eq('foo')
      end

      it 'should set @args[0]' do
        bootstrap_action.value = 'foo'
        expect(bootstrap_action.args[1]).to eq('foo')
      end
    end
  end

end