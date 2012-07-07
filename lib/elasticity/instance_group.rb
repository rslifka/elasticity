module Elasticity

  class InstanceGroup

    ROLES = %w(MASTER CORE TASK)

    attr_accessor :count
    attr_accessor :type
    attr_accessor :role

    attr_reader :bid_price
    attr_reader :market

    def initialize
      @count = 1
      @type = 'm1.small'
      @market = 'ON_DEMAND'
      @role = 'CORE'
    end

    def count=(instance_count)
      raise_if instance_count <= 0, ArgumentError, "Instance groups require at least 1 instance (#{instance_count} requested)"
      raise_if @role == 'MASTER' && instance_count != 1, ArgumentError, "MASTER instance groups can only have 1 instance (#{instance_count} requested)"
      @count = instance_count
    end

    def role=(group_role)
      raise_unless ROLES.include?(group_role), ArgumentError, "Role must be one of MASTER, CORE or TASK (#{group_role} was requested)"
      @count = 1 if group_role == 'MASTER'
      @role = group_role
    end

    def set_spot_instances(bid_price)
      raise_unless bid_price > 0, ArgumentError, "The bid price for spot instances should be greater than 0 (#{bid_price} requested)"
      @bid_price = bid_price
      @market = 'SPOT'
    end

    def set_on_demand_instances
      @bid_price = nil
      @market = 'ON_DEMAND'
    end

    def to_aws_instance_config
      {
        :market => @market,
        :instance_count => @count,
        :instance_type => @type,
        :instance_role => @role,
      }.tap do |config|
        config.merge!(:bid_price => @bid_price) if @market == 'SPOT'
      end
    end

  end

end