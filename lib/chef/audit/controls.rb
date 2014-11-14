
require 'chef/audit/audit_event_proxy'

class Chef
  class Audit
    class Controls

      attr_reader :run_context
      private :run_context

      ::RSpec::Core::ExampleGroup.define_example_group_method :control
      ::RSpec::Core::ExampleGroup.define_example_group_method :__controls__

      def initialize(run_context, *args, &block)
        require 'rspec'
        require 'rspec/its'
        require 'serverspec/matcher'
        require 'serverspec/helper'
        require 'serverspec/subject'
        require 'specinfra'

        @run_context = run_context
        configure
        world.register(RSpec::Core::ExampleGroup.__controls__(*args, &block))
      end

      def run
        RSpec::Core::Runner.new(nil, configuration, world).run_specs(world.ordered_example_groups)
      end

      private
      def configuration
        RSpec.configuration
      end

      def world
        RSpec.world
      end

      def configure
        configuration.output_stream = Chef::Config[:log_location]
        configuration.error_stream = Chef::Config[:log_location]

        add_formatters
        disable_should_syntax
        configure_specinfra
      end

      def add_formatters
        configuration.add_formatter(RSpec::Core::Formatters::DocumentationFormatter)
        configuration.add_formatter(Chef::Audit::AuditEventProxy)
        Chef::Audit::AuditEventProxy.events = run_context.events
      end

      def disable_should_syntax
        RSpec.configure do |config|
          config.expect_with :rspec do |c|
            c.syntax = :expect
          end
        end
      end

      def configure_specinfra
        Specinfra.configuration.backend = :exec
      end

    end
  end
end
