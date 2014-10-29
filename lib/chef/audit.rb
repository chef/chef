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

require 'rspec/core'

require 'chef/config'

class Chef
  class Audit

    def initialize
      @configuration = RSpec::Core::Configuration.new
      @world = RSpec::Core::World.new(@configuration)
      @runner = RSpec::Core::Runner.new(nil, @configuration, @world)
    end

    def setup
      @configuration.output_stream = Chef::Config[:log_location]
      @configuration.error_stream = Chef::Config[:log_location]

      configure_formatters
      configure_expectation_frameworks
    end

    private
    # Adds formatters to RSpec.
    # By default, two formatters are added: one for outputting readable text
    # of audits run and one for sending JSON data back to reporting.
    def configure_formatters
      # TODO (future): We should allow for an audit-mode formatter config option
      # and use this formatter as default/fallback if none is specified.
      @configuration.add_formatter(RSpec::Core::Formatters::DocumentationFormatter)
      # TODO: Add JSON formatter for audit reporting to analytics.
    end

    def configure_expectation_frameworks
      @configuration.expect_with(:rspec) do |config|
        # :should is deprecated in RSpec 3+ and we have chosen to explicitly disable
        # it in audits. If :should is used in an audit, this will cause the audit to
        # fail with message "undefined method `should`" rather than print a deprecation
        # message.
        config.syntax = :expect
      end

      #TODO: serverspec?
    end

  end
end
