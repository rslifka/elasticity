RSpec::Matchers.define :be_a_hash_including do |expected|
  match do |actual|
    next false unless actual.is_a? Hash
    next false unless expected.is_a? Hash
    expected.keys.each do |key|
      break false if actual[key] != expected[key]
      true
    end
  end
end

describe :be_a_hash_including do

  context 'when actual is not a Hash' do
    subject { 'I AM NOT A HASH' }
    it { should_not be_a_hash_including({}) }
  end

  context 'when expected is not a Hash' do
    subject { {} }
    it { should_not be_a_hash_including('') }
  end

  context 'when expected is included in actual' do
    subject {{:actual_key1 => 'value1'}}
    it { should be_a_hash_including({:actual_key1 => 'value1'})}
  end

  context 'when expected is not included in actual' do
    subject {{:actual_key1 => 'value1'}}
    it { should_not be_a_hash_including({:actual_key3 => 'value3'})}
  end

end

