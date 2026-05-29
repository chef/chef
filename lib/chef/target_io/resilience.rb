require "timeout" unless defined?(Timeout)

module TargetIO
  module Resilience
    ENABLED_ENV = "CHEF_TARGET_IO_RESILIENCE_ENABLED".freeze
    MAX_ATTEMPTS_ENV = "CHEF_TARGET_IO_RESILIENCE_MAX_ATTEMPTS".freeze
    TIMEOUT_SECONDS_ENV = "CHEF_TARGET_IO_RESILIENCE_TIMEOUT_SECONDS".freeze
    BACKOFF_BASE_SECONDS_ENV = "CHEF_TARGET_IO_RESILIENCE_BACKOFF_BASE_SECONDS".freeze
    BACKOFF_MAX_SECONDS_ENV = "CHEF_TARGET_IO_RESILIENCE_BACKOFF_MAX_SECONDS".freeze

    DEFAULT_ENABLED = true
    DEFAULT_MAX_ATTEMPTS = 3
    DEFAULT_TIMEOUT_SECONDS = 10.0
    DEFAULT_BACKOFF_BASE_SECONDS = 0.25
    DEFAULT_BACKOFF_MAX_SECONDS = 2.0

    class << self
      def with_timeout_and_backoff(operation:)
        return yield unless enabled?

        attempt = 0
        begin
          attempt += 1
          Timeout.timeout(timeout_seconds) { return yield }
        rescue Timeout::Error, StandardError => e
          raise if attempt >= max_attempts

          delay = retry_delay_seconds(attempt)
          Chef::Log.warn("TargetIO resilience retry for #{operation} (attempt #{attempt}/#{max_attempts}, #{e.class}: #{e.message})")
          sleep_for(delay)
          retry
        end
      end

      def enabled?
        parse_bool(ENABLED_ENV, DEFAULT_ENABLED)
      end

      def max_attempts
        value = parse_integer(MAX_ATTEMPTS_ENV, DEFAULT_MAX_ATTEMPTS)
        [value, 1].max
      end

      def timeout_seconds
        value = parse_float(TIMEOUT_SECONDS_ENV, DEFAULT_TIMEOUT_SECONDS)
        [value, 0.01].max
      end

      def backoff_base_seconds
        value = parse_float(BACKOFF_BASE_SECONDS_ENV, DEFAULT_BACKOFF_BASE_SECONDS)
        [value, 0.0].max
      end

      def backoff_max_seconds
        value = parse_float(BACKOFF_MAX_SECONDS_ENV, DEFAULT_BACKOFF_MAX_SECONDS)
        [value, 0.0].max
      end

      def retry_delay_seconds(attempt)
        base = backoff_base_seconds
        max = backoff_max_seconds
        delay = base * (2**(attempt - 1))

        [delay, max].min
      end

      def sleep_for(seconds)
        sleep(seconds) if seconds.positive?
      end

      private

      def parse_bool(key, default)
        value = ENV[key]
        return default if value.nil? || value.empty?

        %w{1 true yes on}.include?(value.strip.downcase)
      end

      def parse_integer(key, default)
        value = ENV[key]
        return default if value.nil? || value.empty?

        Integer(value)
      rescue ArgumentError
        default
      end

      def parse_float(key, default)
        value = ENV[key]
        return default if value.nil? || value.empty?

        Float(value)
      rescue ArgumentError
        default
      end
    end
  end
end