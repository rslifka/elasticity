module Elasticity

  class Looper

    def initialize(on_retry_check, on_wait)
      @on_retry_check = on_retry_check
      @on_wait = on_wait
    end

    def go
      loop do
        break unless @on_retry_check.call
        @on_wait.call
      end
    end

  end

end