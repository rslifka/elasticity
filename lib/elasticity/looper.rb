module Elasticity

  class Looper

    def initialize(poll_interval = 60, on_retry_check, on_wait)
      @on_retry_check = on_retry_check
      @on_wait = on_wait
      @poll_interval = poll_interval
    end

    def go
      start_time = Time.now
      loop do
        should_continue, *results = @on_retry_check.call
        return unless should_continue
        @on_wait.call(Time.now - start_time, *results)
        sleep(@poll_interval)
      end
    end

  end

end