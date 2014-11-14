#
# Author:: Claire McQuin (<claire@getchef.com>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/audit/audit_event_proxy'

class Chef
  class Audit
    class Controls

      attr_reader :run_context
      private :run_context

      ::RSpec::Core::ExampleGroup.define_example_group_method :control
      ::RSpec::Core::ExampleGroup.define_example_group_method :__controls__

      def initialize(run_context, *args, &block)
        # To avoid cross-contamination between the configuration in our and other
        # spec/spec_helper.rb files and the configuration for audits, we give
        # each `controls` group its own RSpec. The files required here manipulate
        # RSpec's global configuration, so we wait to load them.
        #
        # Additionally, name conflicts emerged between Chef's `package` and
        # Serverspec's `package`. Requiring serverspec in here eliminates those
        # namespace conflict.
        #
        # TODO: Once we have specs written for audit-mode, I'd like to play with
        # which files can be moved around. I'm concerned about how much overhead
        # we introduce by sequestering RSpec by `controls` group instead of in
        # a common class or shared module.
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
        # The first parameter passed to RSpec::Core::Runner.new
        # is an instance of RSpec::Core::ConfigurationOptions, which is
        # responsible for processing command line options passed through rspec.
        # This then gets merged with the configuration. We'll just communicate
        # directly with the Configuration here.
        RSpec::Core::Runner.new(nil, configuration, world).run_specs(world.ordered_example_groups)
      end

      private
      def configuration
        RSpec.configuration
      end

      def world
        RSpec.world
      end

      # Sets up where output and error streams should stream to, adds formatters
      # for people-friendly output of audit results and json for reporting. Also
      # configures expectation frameworks.
      def configure
        # We're setting the output stream, but that will only be used for error situations
        # Our formatter forwards events to the Chef event message bus
        # TODO so some testing to see if these output to a log file - we probably need
        # to register these before any formatters are added.
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

      # Explicitly disable :should syntax.
      #
      # :should is deprecated in RSpec 3 and we have chosen to explicitly disable it
      # in audits. If :should is used in an audit, the audit will fail with error
      # message "undefined method `:should`" rather than issue a deprecation warning.
      #
      # This can be removed when :should is fully removed from RSpec.
      def disable_should_syntax
        RSpec.configure do |config|
          config.expect_with :rspec do |c|
            c.syntax = :expect
          end
        end
      end

      def configure_specinfra
        # TODO: We may need to change this based on operating system (there is a
        # powershell backend) or roll our own.
        Specinfra.configuration.backend = :exec
      end

    end
  end
end
