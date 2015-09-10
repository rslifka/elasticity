describe Elasticity::Application do

  let(:config) do
    {
      name: 'name',
      version: '1.0.0',
      arguments: 'arguments',
      additional_info: 'additional_info'
    }
  end

  subject { described_class.new(config) }

  describe '#to_hash' do
    it 'has all configuration' do
      expect(subject.to_hash).to eq(
        name: "name",
        args: "arguments",
        version: "1.0.0",
        additional_info: "additional_info"
      )
    end
  end
end
