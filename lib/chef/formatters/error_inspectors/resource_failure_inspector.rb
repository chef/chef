#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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
require "chef-utils" unless defined?(ChefUtils::CANARY)

class Chef
  module Formatters
    module ErrorInspectors
      class ResourceFailureInspector

        attr_reader :resource
        attr_reader :action
        attr_reader :exception

        def initialize(resource, action, exception)
          @resource = resource
          @action = action
          @exception = exception
        end

        def add_explanation(error_description)
          error_description.section(exception.class.name, exception.message)

          unless filtered_bt.empty?
            error_description.section("Cookbook Trace: (most recent call first)", filtered_bt.join("\n"))
          end

          unless dynamic_resource?
            error_description.section("Resource Declaration:", resource.sensitive ? "suppressed sensitive resource output" : recipe_snippet)
          end

          error_description.section("Compiled Resource:", (resource.to_text).to_s)

          # Template errors get wrapped in an exception class that can show the relevant template code,
          # so add them to the error output.
          if exception.respond_to?(:source_listing)
            error_description.section("Template Context:", "#{exception.source_location}\n#{exception.source_listing}")
          end

          if ChefUtils.windows?
            require_relative "../../win32/security"

            unless Chef::ReservedNames::Win32::Security.has_admin_privileges?
              error_description.section("Missing Windows Admin Privileges", "#{ChefUtils::Dist::Infra::CLIENT} doesn't have administrator privileges. This can be a possible reason for the resource failure.")
            end
          end
        end

        def recipe_snippet
          return nil if dynamic_resource?

          @snippet ||= if (file = parse_source) && (line = parse_line(file))
                         return nil unless ::File.exist?(file)

                         lines = IO.readlines(file)

                         relevant_lines = ["# In #{file}\n\n"]

                         current_line = line - 1
                         current_line = 0 if current_line < 0
                         nesting = 0

                         loop do

                           # low rent parser. try to gracefully handle nested blocks in resources
                           nesting += 1 if /\s+do\s*/.match?(lines[current_line])
                           nesting -= 1 if /end\s*$/.match?(lines[current_line])

                           relevant_lines << format_line(current_line, lines[current_line])

                           break if lines[current_line + 1].nil?
                           break if current_line >= (line + 50)
                           break if nesting <= 0

                           current_line += 1
                         end
                         relevant_lines << format_line(current_line + 1, lines[current_line + 1]) if lines[current_line + 1]
                         relevant_lines.join("")
                       end
        end

        def dynamic_resource?
          !resource.source_line
        end

        def filtered_bt
          filters = Array(Chef::Config.cookbook_path).map { |p| /^#{Regexp.escape(p)}/ }
          exception.backtrace.select { |line| filters.any? { |filter| line =~ filter } }
        end

        private

        def format_line(line_nr, line)
          # Print line number as 1-indexed not zero
          line_nr_string = (line_nr + 1).to_s.rjust(3) + ": "
          line_nr_string + line
        end

        def parse_source
          resource.source_line[/^((\w:)?[^:]+):(\d+)/, 1]
        end

        def parse_line(source)
          resource.source_line[/^#{Regexp.escape(source)}:(\d+)/, 1].to_i
        end

      end
    end
  end
end
