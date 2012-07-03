module Elasticity

  class InstanceGroup

    attr_accessor :count
    attr_accessor :type
    attr_accessor :name
    attr_accessor :market
    attr_accessor :role

    def initialize
      @count = 1
      @type = 'm1.large'
      @name = 'Elasticity Instance Group'
      @market = 'ON_DEMAND'
      @role = 'CORE'
    end

    def count=(instance_count)
      raise_if instance_count <= 0, ArgumentError, "Instance groups require at least 1 instance (#{instance_count} requested)"
      raise_if @role == 'MASTER' && instance_count != 1, ArgumentError, "MASTER instance groups can only have 1 instance (#{instance_count} requested)"
      @count = instance_count
    end

  end

end