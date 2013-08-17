module Elasticity

  class Looper

    def initialize(poll_interval = 60, on_retry_check, on_wait)
      @on_retry_check = on_retry_check
      @on_wait = on_wait
      @poll_interval = poll_interval
    end

    def go
      loop do
        should_continue = @on_retry_check.call
        return unless should_continue
        @on_wait.call
        sleep(@poll_interval)
      end
    end

  end

end