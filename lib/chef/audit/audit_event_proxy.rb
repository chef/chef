RSpec::Support.require_rspec_core "formatters/base_text_formatter"

class Chef
  class Audit
    class AuditEventProxy < ::RSpec::Core::Formatters::BaseFormatter
      ::RSpec::Core::Formatters.register self, :example_group_started, :example_group_finished,
                                         :example_passed, :example_failed

      # TODO I don't like this, but I don't see another way to pass this in
      # see configuration.rb#L671 and formatters.rb#L129
      def self.events=(events)
        @@events = events
      end

      def events
        @@events
      end

      def example_group_started(notification)
        events.control_group_start(notification.group.description.strip)
      end

      def example_group_finished(_notification)
        events.control_group_end
      end

      def example_passed(passed)
        events.control_example_success(passed.example.description.strip)
      end

      def example_failed(failed)
        events.control_example_failure(failed.example.description.strip, failed.example.execution_result.exception)
      end

      private

      def example_group_chain
        example_group.parent_groups.reverse
      end
    end
  end
end
