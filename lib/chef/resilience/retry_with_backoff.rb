class Chef
  module Resilience
    module RetryWithBackoff
      module_function

      # Runs the block with retry and exponential backoff for selected errors.
      def call(max_attempts:, base_delay:, retry_on:, sleeper:, on_retry: nil)
        attempts = 0

        begin
          attempts += 1
          return yield
        rescue *Array(retry_on) => error
          raise if attempts >= max_attempts

          delay = base_delay * (2**(attempts - 1))
          on_retry.call(error, attempts, delay) if on_retry
          sleeper.__send__(:sleep, delay)
          retry
        end
      end
    end
  end
end
