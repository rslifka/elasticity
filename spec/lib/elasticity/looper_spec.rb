describe Elasticity::Looper do

  before do
    Elasticity::Looper.any_instance.stub(:sleep)
  end

  context 'when you should wait' do

    let(:client) do
      double(:client).tap do |c|
        # Retry on the first pass through and don't retry on the second
        c.stub(:on_retry_check).and_return(true, false)
        c.stub(:on_wait)
      end
    end

    context 'and then you should not wait' do

      context 'when a wait callback is provided' do

        it 'communicates that waiting occurs only once' do
          client.should_receive(:on_wait).once
          l = Elasticity::Looper.new(client.method(:on_retry_check), client.method(:on_wait))
          l.go
        end

        it 'communicates waiting occurs with elapsed wait time and arguments that on_retry_check returns' do
          # Freeze time at the start and then 60 seconds ahead when sleep is called
          Timecop.freeze(Time.at(1300000000))
          Elasticity::Looper.any_instance.stub(:sleep) do
            Timecop.freeze(Time.at(1300000060))
          end

          client.stub(:on_retry_check).and_return([true, 'TEST1', 'TEST2'], [true, 'TEST3'], false)
          client.should_receive(:on_wait).with(0, 'TEST1', 'TEST2')
          client.should_receive(:on_wait).with(60, 'TEST3')

          l = Elasticity::Looper.new(client.method(:on_retry_check), client.method(:on_wait))
          l.go

          Timecop.return
        end

      end

      context 'when a wait callback is not provided' do
        it 'still works' do
          l = Elasticity::Looper.new(client.method(:on_retry_check), nil)
          l.go

          l = Elasticity::Looper.new(client.method(:on_retry_check))
          l.go
        end
      end

    end

    context 'when no poll interval is specified' do
      it 'should poll every 60 seconds' do
        Elasticity::Looper.any_instance.should_receive(:sleep).with(60)
        l = Elasticity::Looper.new(client.method(:on_retry_check), client.method(:on_wait))
        l.go
      end
    end

    context 'when a custom poll interview is specified' do
      it 'should poll at that interval' do
        Elasticity::Looper.any_instance.should_receive(:sleep).with(999)
        l = Elasticity::Looper.new(client.method(:on_retry_check), client.method(:on_wait), 999)
        l.go
      end
    end

  end

  context 'when you should not wait' do

    it 'does not communicate that waiting is about to occur' do
      client = double(:client, on_retry_check: false, on_wait: nil)
      client.should_not_receive(:on_wait)
      l = Elasticity::Looper.new(client.method(:on_retry_check), client.method(:on_wait))
      l.go
    end

  end

end
