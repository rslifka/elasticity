describe Elasticity::BootstrapAction do

  subject do
    Elasticity::BootstrapAction.new('script', 'arg1', 'arg2')
  end

  describe '.initialize' do
    expect(subject.name).to eq('Elasticity Bootstrap Action')
    expect(subject.script).to eq('script')
    expect(subject.arguments).to eq(%w(arg1 arg2))
  end

  describe '#to_aws_bootstrap_action' do

    let(:aws_bootstrap_step) {
      {
        :name => 'Elasticity Bootstrap Action',
        :script_bootstrap_action => {
          :path => 'script'
        }
      }
    }

    context 'when there are no arguments' do
      let(:bootstrap_action) { Elasticity::BootstrapAction.new('script') }
      it 'should create a proper bootstrap action' do
        expect(bootstrap_action.to_aws_bootstrap_action).to eq(aws_bootstrap_step)
      end
    end

    context 'when there are arguments' do
      let(:bootstrap_action) { Elasticity::BootstrapAction.new('script', 'arg1', 'arg2') }
      before do
        aws_bootstrap_step[:script_bootstrap_action][:args] = %w(arg1 arg2)
      end
      it 'should create a proper bootstrap action' do
        expect(subject.to_aws_bootstrap_action).to be_a_hash_including(aws_bootstrap_step)
      end
    end

  end

end