module TargetIO
  module FeatureFlags
    TARGET_IO_BACKEND_HELPER_ENV = "CHEF_TARGET_IO_BACKEND_HELPER".freeze
    TRUE_VALUES = %w{1 true yes on}.freeze

    class << self
      def target_io_backend_helper_enabled?
        enabled = TRUE_VALUES.include?(ENV[TARGET_IO_BACKEND_HELPER_ENV].to_s.strip.downcase)
        telemetry_log_flag_state(enabled)
        enabled
      end

      def choose_backend(name:, target_backend:, local_backend:)
        target_mode = ChefConfig::Config.target_mode?
        backend = target_mode ? target_backend : local_backend
        Chef::Log.debug("#{name} backend selected: #{backend} (target_mode=#{target_mode})")
        backend
      end

      # Test helper to ensure each example can assert telemetry independently.
      def reset_flag_state_for_testing!
        @last_logged_state = nil
      end

      private

      def telemetry_log_flag_state(enabled)
        return if @last_logged_state == enabled

        @last_logged_state = enabled
        Chef::Log.info("TargetIO feature flag #{TARGET_IO_BACKEND_HELPER_ENV}=#{enabled}")
      end
    end
  end
end
