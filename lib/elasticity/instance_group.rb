module Elasticity

  class InstanceGroup

    ROLES = %w(MASTER CORE TASK)

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

    def role=(group_role)
      raise_unless ROLES.include?(group_role), ArgumentError, "Role must be one of MASTER, CORE or TASK (#{group_role} was requested)"
      @count = 1 if group_role == 'MASTER'
      @role = group_role
    end

  end

end