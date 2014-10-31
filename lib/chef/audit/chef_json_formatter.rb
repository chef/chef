RSpec::Support.require_rspec_core "formatters/base_formatter"
require 'chef/audit/control_group_data'
require 'ffi_yajl'

class Chef
  class Audit
    class ChefJsonFormatter < ::RSpec::Core::Formatters::BaseFormatter
      ::RSpec::Core::Formatters.register self, :example_group_started, :message, :stop, :close, :example_failed

      attr_reader :control_group_data

      # TODO hopefully the runner can take care of this for us since there won't be an outer-most
      # control group
      @@outer_example_group_found = false

      def initialize(output)
        super
      end

      # Invoked for each `control`, `describe`, `context` block
      def example_group_started(notification)
        unless @@outer_example_group_found
          @control_group_data = ControlGroupData.new(notification.group.description)
          @@outer_example_group_found = true
        end
      end

      def example_failed(notification)
        e = notification.example.metadata[:execution_result].exception
        raise e unless e.kind_of? ::RSpec::Expectations::ExpectationNotMetError
      end

      def message(notification)
        puts "message: #{notification}"
      end

      def stop(notification)
        notification.examples.each do |example|
          control_data = build_control_from(example)
          e = example.exception
          if e
            control = control_group_data.example_failure(e.message, control_data)
          else
            control = control_group_data.example_success(control_data)
          end
          control.line_number = example.metadata[:line_number]
        end
      end

      def close(notification)
        output.write FFI_Yajl::Encoder.encode(control_group_data.to_hash, pretty: true)
        output.close if IO === output && output != $stdout
      end

      private

      def build_control_from(example)
        described_class = example.metadata[:described_class]
        if described_class
          resource_type = described_class.class.name.split(':')[-1]
          # TODO submit github PR to expose this
          resource_name = described_class.instance_variable_get(:@name)
        end

        describe_groups = []
        group = example.metadata[:example_group]
        # If the innermost block has a resource instead of a string, don't include it in context
        describe_groups.unshift(group[:description]) if described_class.nil?
        group = group[:parent_example_group]
        while !group.nil?
          describe_groups.unshift(group[:description])
          group = group[:parent_example_group]
        end
        # TODO remove this when we're no longer wrapping everything with "mysql audit"
        describe_groups.shift

        {
            :name => example.description,
            :desc => example.full_description,
            :resource_type => resource_type,
            :resource_name => resource_name,
            :context => describe_groups
        }
      end

    end
  end
end
