describe Elasticity::InstanceGroup do

  describe '.initialize' do
    it 'should set the fields appropriately' do
      expect(subject.bid_price).to eql(nil)
      expect(subject.count).to eql(1)
      expect(subject.type).to eql('m1.small')
      expect(subject.market).to eql('ON_DEMAND')
      expect(subject.role).to eql('CORE')
      expect(subject.ebs_configuration).to eql(nil)
    end
  end

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
      expect(subject.market).to eq('SPOT')
      expect(subject.bid_price).to eq('0.25')
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

  describe '#set_ebs_configuration' do

    it 'should not change if the type is incorrect' do
      subject.set_ebs_configuration("ebs_configuration")
      subject.ebs_configuration.should == nil
    end

    it 'should change if the type is correct' do
      subject.set_ebs_configuration(Elasticity::EbsConfiguration.new)
      subject.ebs_configuration.should_not == nil
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
          :bid_price => '0.25',
          :instance_count => 5,
          :instance_type => 'c1.medium',
          :instance_role => 'CORE',
        }
      end
    end

    context 'when a EBS configuration' do
      let(:on_demand_instance_group) do
        Elasticity::InstanceGroup.new.tap do |i|
          i.count = 5
          i.type = 'c1.medium'
          i.role = 'CORE'
          i.set_ebs_configuration(
            Elasticity::EbsConfiguration.new.tap do |ebs|
              ebs.add_ebs_block_device_config(Elasticity::EbsBlockDeviceConfig.new)
              ebs.add_ebs_block_device_config(
                Elasticity::EbsBlockDeviceConfig.new.tap do |ebsc|
                  ebsc.size_in_gb = 10000
                  ebsc.volumes_per_instance = 10
                  ebsc.iops = 9999
                  ebsc.volume_type = "io1"
                end
              )
            end
          )
        end
      end
      it 'should generate an AWS config' do
        on_demand_instance_group.ebs_configuration.ebs_block_device_configs.length.should == 2
        on_demand_instance_group.to_aws_instance_config.should == {
          :market => 'ON_DEMAND',
          :instance_count => 5,
          :instance_type => 'c1.medium',
          :instance_role => 'CORE',
          :ebs_configuration => {
            :ebs_block_device_configs => [
              {
                :volume_specification => {
                  :volume_type => "gp2",
                  :size_in_gb => 1,
                },
                :volumes_per_instance => 1
              },
              {
                :volume_specification => {
                  :volume_type => "io1",
                  :iops => 9999,
                  :size_in_gb => 10000,
                },
                :volumes_per_instance => 10
              },
            ],
            :ebs_optimized => false,
          },
        }
      end
    end

  end

end
