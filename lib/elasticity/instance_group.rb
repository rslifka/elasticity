module Elasticity

  class InstanceGroup

    ROLES = %w(MASTER CORE TASK)

    attr_accessor :count
    attr_accessor :type
    attr_accessor :role

    attr_reader :ebs_configuration
    attr_reader :bid_price
    attr_reader :market

    def initialize
      @count = 1
      @type = 'm1.small'
      @market = 'ON_DEMAND'
      @role = 'CORE'
    end

    def count=(instance_count)
      if instance_count <= 0
        raise ArgumentError, "Instance groups require at least 1 instance (#{instance_count} requested)"
      end
      if @role == 'MASTER' && instance_count != 1
        raise ArgumentError, "MASTER instance groups can only have 1 instance (#{instance_count} requested)"
      end
      @count = instance_count
    end

    def role=(group_role)
      if !ROLES.include?(group_role)
        raise ArgumentError, "Role must be one of MASTER, CORE or TASK (#{group_role} was requested)"
      end
      @count = 1 if group_role == 'MASTER'
      @role = group_role
    end

    def set_spot_instances(bid_price)
      if bid_price < 0
        raise ArgumentError, "The bid price for spot instances should be greater than 0 (#{bid_price} requested)"
      end
      @bid_price = "#{bid_price}"
      @market = 'SPOT'
    end

    def set_on_demand_instances
      @bid_price = nil
      @market = 'ON_DEMAND'
    end

    def set_ebs_configuration(ebs_configuration)
      if ebs_configuration.is_a?(Elasticity::EbsConfiguration)
        @ebs_configuration = ebs_configuration
      end
    end

    def to_aws_instance_config
      {
        :market => @market,
        :instance_count => @count,
        :instance_type => @type,
        :instance_role => @role,
      }.tap do |config|
        config.merge!(:bid_price => @bid_price) if @market == 'SPOT'
        config.merge!(:ebs_configuration => @ebs_configuration.to_aws_ebs_config) if @ebs_configuration != nil
      end
    end

  end

  class EbsConfiguration

    attr_accessor :ebs_optimized

    attr_reader :ebs_block_device_configs

    def initialize
      @ebs_optimized = false
      @ebs_block_device_configs = Array.new
    end

    def add_ebs_block_device_config(ebs_block_device_config)
      if ebs_block_device_config.is_a?(Elasticity::EbsBlockDeviceConfig)
        @ebs_block_device_configs.push(ebs_block_device_config)
      end
    end

    def to_aws_ebs_config
      {
        :ebs_optimized => @ebs_optimized,
        :ebs_block_device_configs => @ebs_block_device_configs.map {
          |i| i.to_aws_ebs_block_device_config
        }
      }
    end
  end

  class EbsBlockDeviceConfig

    attr_accessor :volume_type
    attr_accessor :iops
    attr_accessor :size_in_gb
    attr_accessor :volumes_per_instance

    def initialize
      @volume_type = "gp2"
      @iops = 1
      @size_in_gb = 1
      @volumes_per_instance = 1
    end

    def to_aws_ebs_block_device_config
      {
        :volume_specification => {
          :volume_type => @volume_type,
          :size_in_gb => @size_in_gb,
        }.tap do |spec|
          spec.merge!(:iops => @iops) if @volume_type == "io1"
        end,
        :volumes_per_instance => @volumes_per_instance
      }
    end
  end

end
