module Elasticity
  class Application

    attr_accessor :name
    attr_accessor :arguments
    attr_accessor :version
    attr_accessor :additional_info

    def initialize(args)
      @name = args[:name]
      @arguments = args[:arguments]
      @version = args[:version]
      @additional_info = args[:additional_info]
    end

    def to_hash
      application = {
        name: @name
      }
      application[:args] = @arguments unless @arguments.nil? || @arguments.empty?
      application[:version] = @version if @version
      application[:additional_info] = @additional_info if @additional_info
      application
    end

  end
end
