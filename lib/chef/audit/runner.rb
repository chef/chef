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

require 'chef/audit'
require 'chef/config'

class Chef
  class Audit
    class Runner

      def initialize(run_context)
        @run_context = run_context
      end

      def run
        setup
        register_controls_groups

        # The first parameter passed to RSpec::Core::Runner.new
        # is an instance of RSpec::Core::ConfigurationOptions, which is
        # responsible for processing command line options passed through rspec.
        # This then gets merged with the configuration. We'll just communicate
        # directly with the Configuration here.
        audit_runner = RSpec::Core::Runner.new(nil, configuration, world)
        audit_runner.run_specs(world.ordered_example_groups)
      end

      private

      # RSpec configuration and world objects are heavy, so let's wait until
      # we actually need them.
      def configuration
        @configuration ||= RSpec::Core::Configuration.new
      end

      def world
        @world ||= RSpec::Core::World.new(configuration)
      end

      # Configure audits before run.
      # Sets up where output and error streams should stream to, adds formatters
      # for people-friendly output of audit results and json for reporting. Also
      # configures expectation frameworks.
      def setup
        configuration.output_stream = Chef::Config[:log_location]
        configuration.error_stream  = Chef::Config[:log_location]

        add_formatters
        disable_should_syntax
      end

      def add_formatters
        configuration.add_formatter(RSpec::Core::Formatters::DocumentationFormatter)
        configuration.add_formatter(ChefJsonFormatter)
      end

      # Explicitly disable :should syntax.
      #
      # :should is deprecated in RSpec 3 and we have chosen to explicitly disable it
      # in audits. If :should is used in an audit, the audit will fail with error
      # message "undefined method `:should`" rather than issue a deprecation warning.
      #
      # This can be removed when :should is fully removed from RSpec.
      def disable_should_syntax
        configuration.expect_with :rspec do |c|
          c.syntax = :expect
        end
      end

      # Register each controls group with the world, which will handle
      # the ordering of the audits that will be run.
      def register_controls_groups
        @run_context.controls_groups.each { |ctls_grp| world.register(ctls_grp) }
      end

    end
  end
end
