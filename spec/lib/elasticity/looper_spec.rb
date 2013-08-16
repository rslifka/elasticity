describe Elasticity::Looper do

  context 'when you should wait' do

    context 'and then you should not wait' do

      it 'does not communication that waiting is about to occur' do
        f = double(:client)
        f.stub(:on_retry_check).and_return(true, false)
        f.stub(:on_wait)

        l = Elasticity::Looper.new(f.method(:on_retry_check), f.method(:on_wait))
        l.go

        expect(f).to have_received(:on_wait).once
      end

    end

  end

  context 'when you should not wait' do

    it 'does not communicate that waiting is about to occur' do
      f = double(:client, on_retry_check: false, on_wait: nil)

      l = Elasticity::Looper.new(f.method(:on_retry_check), f.method(:on_wait))
      l.go

      expect(f).to_not have_received(:on_wait)
    end

  end

end
