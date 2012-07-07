describe Elasticity::InstanceGroup do

  its(:bid_price) { should == nil }
  its(:count) { should == 1 }
  its(:type) { should == 'm1.small' }
  its(:market) { should == 'ON_DEMAND' }
  its(:role) { should == 'CORE' }

  describe '#count=' do

    it 'should set the count' do
      subject.count = 10
      subject.count.should == 10
    end

    context 'when the role is not MASTER' do
      context 'and the count is <= 0' do
        it 'should be an error' do
          subject.role = 'CORE'
          expect {
            subject.count = 0
          }.to raise_error(ArgumentError, 'Instance groups require at least 1 instance (0 requested)')
        end
      end
    end

    context 'when the role is MASTER' do
      context 'and a count != 1 is attempted' do
        it 'should be an error' do
          subject.role = 'MASTER'
          expect {
            subject.count = 2
          }.to raise_error(ArgumentError, 'MASTER instance groups can only have 1 instance (2 requested)')
        end
      end
    end

  end

  describe '#role=' do

    it 'should set the role' do
      subject.role = 'MASTER'
      subject.role.should == 'MASTER'
    end

    context 'when the role is unknown' do
      it 'should be an error' do
        expect {
          subject.role = '_'
        }.to raise_error(ArgumentError, 'Role must be one of MASTER, CORE or TASK (_ was requested)')
      end
    end

    context 'when the role is switching to MASTER' do
      context 'and the count is != 1' do
        it 'should set the count to 1' do
          subject.role = 'CORE'
          subject.count = 2
          expect {
            subject.role = 'MASTER'
          }.to change { subject.count }.to(1)
        end
      end
    end

  end

  describe '#set_spot_instances' do

    it 'should set the type and price' do
      subject.set_spot_instances(0.25)
      subject.market.should == 'SPOT'
      subject.bid_price.should == 0.25
    end

    context 'when the price is <= 0' do
      it 'should be an error' do
        expect {
          subject.set_spot_instances(-1)
        }.to raise_error(ArgumentError, 'The bid price for spot instances should be greater than 0 (-1 requested)')
      end
    end

  end

  describe '#set_on_demand_instances' do

    it 'should set the type and price' do
      subject.set_on_demand_instances
      subject.market.should == 'ON_DEMAND'
      subject.bid_price.should == nil
    end

  end

  describe '#to_aws_instance_config' do

    context 'when an ON_DEMAND group' do
      let(:on_demand_instance_group) do
        Elasticity::InstanceGroup.new.tap do |i|
          i.count = 5
          i.type = 'c1.medium'
          i.role = 'CORE'
          i.set_on_demand_instances
        end
      end
      it 'should generate an AWS config' do
        on_demand_instance_group.to_aws_instance_config.should == {
          :market => 'ON_DEMAND',
          :instance_count => 5,
          :instance_type => 'c1.medium',
          :instance_role => 'CORE',
        }
      end
    end

    context 'when a SPOT group' do
      let(:on_demand_instance_group) do
        Elasticity::InstanceGroup.new.tap do |i|
          i.count = 5
          i.type = 'c1.medium'
          i.role = 'CORE'
          i.set_spot_instances(0.25)
        end
      end
      it 'should generate an AWS config' do
        on_demand_instance_group.to_aws_instance_config.should == {
          :market => 'SPOT',
          :bid_price => 0.25,
          :instance_count => 5,
          :instance_type => 'c1.medium',
          :instance_role => 'CORE',
        }
      end
    end

  end

end