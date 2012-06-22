module Elasticity

  module ConditionalRaising

    def raise_if(conditional, error_class, message)
      raise error_class, message if conditional
    end

    def raise_unless(conditional, error_class, message)
      raise error_class, message unless conditional
    end

  end

end

module Kernel
  include Elasticity::ConditionalRaising
end

class Object
  include Kernel
end
