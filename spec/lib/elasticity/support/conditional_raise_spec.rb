describe 'Conditional Raising' do

  describe '#raise_if' do

    it 'should raise the specified error if the condition is true' do
      expect {
        raise_if true, RuntimeError, 'MESSAGE'
      }.to raise_error(RuntimeError, 'MESSAGE')
    end

    it 'should not raise the specified error if the condition is false' do
      expect {
        raise_if false, RuntimeError, 'MESSAGE'
      }.to_not raise_error(RuntimeError, 'MESSAGE')
    end

  end

  describe '#raise_unless' do

    it 'should not raise the specified error unless the condition is true' do
      expect {
        raise_unless true, RuntimeError, 'MESSAGE'
      }.to_not raise_error(RuntimeError, 'MESSAGE')
    end

    it 'should raise the specified error unless the condition is false' do
      expect {
        raise_unless false, RuntimeError, 'MESSAGE'
      }.to raise_error(RuntimeError, 'MESSAGE')
    end

  end

end