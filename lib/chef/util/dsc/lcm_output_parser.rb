#
# Author:: Jay Mundrawala (<jdm@chef.io>)
#
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

require "chef/log"
require "chef/util/dsc/resource_info"
require "chef/exceptions"

class Chef
  class Util
    class DSC
      class LocalConfigurationManager
        module Parser
          # Parses the output from LCM and returns a list of Chef::Util::DSC::ResourceInfo objects
          # that describe how the resources affected the system
          #
          # Example:
          #   parse <<-EOF
          #   What if: [Machine]: LCM: [Start Set      ]
          #   What if: [Machine]: LCM: [Start Resource ] [[File]FileToNotBeThere]
          #   What if: [Machine]: LCM: [Start Set      ] [[File]FileToNotBeThere]
          #   What if:                                   [C:\ShouldNotExist.txt] removed
          #   What if: [Machine]: LCM: [End Set        ] [[File]FileToNotBeThere] in 0.1 seconds
          #   What if: [Machine]: LCM: [End Resource   ] [[File]FileToNotBeThere]
          #   What if: [Machine]: LCM: [End Set        ]
          #   EOF
          #
          #   would return
          #
          #   [
          #     Chef::Util::DSC::ResourceInfo.new(
          #       '[[File]FileToNotBeThere]',
          #       true,
          #       [
          #         '[[File]FileToNotBeThere]',
          #         '[C:\Shouldnotexist.txt]',
          #         '[[File]FileToNotBeThere] in 0.1 seconds'
          #       ]
          #     )
          #   ]
          #
          def self.parse(lcm_output)
            lcm_output ||= ""
            current_resource = Hash.new

            resources = []
            lcm_output.lines.each do |line|
              op_action, op_type, info = parse_line(line)

              case op_action
              when :start
                case op_type
                when :set
                  if current_resource[:name]
                    current_resource[:context] = :logging
                    current_resource[:logs] = [info]
                  end
                when :resource
                  if current_resource[:name]
                    resources.push(current_resource)
                  end
                  current_resource = { :name => info }
                else
                  Chef::Log.debug("Ignoring op_action #{op_action}: Read line #{line}")
                end
              when :end
                # Make sure we log the last line
                if current_resource[:context] == :logging && info.include?(current_resource[:name])
                  current_resource[:logs].push(info)
                end
                current_resource[:context] = nil
              when :skip
                current_resource[:skipped] = true
              when :info
                if current_resource[:context] == :logging
                  current_resource[:logs].push(info)
                end
              end
            end

            if current_resource[:name]
              resources.push(current_resource)
            end

            if resources.length > 0
              build_resource_info(resources)
            else
              raise Chef::Exceptions::LCMParser, "Could not parse:\n#{lcm_output}"
            end
          end

          def self.parse_line(line)
            if match = line.match(/^.*?:.*?:\s*LCM:\s*\[(.*?)\](.*)/)
                # If the line looks like
                # What If: [machinename]: LCM: [op_action op_type] message
                # extract op_action, op_type, and message
              operation, info = match.captures
              op_action, op_type = operation.strip.split(" ").map { |m| m.downcase.to_sym }
            else
              op_action = op_type = :info
              if match = line.match(/^.*?:.*?: \s+(.*)/)
                info = match.captures[0]
              else
                info = line
              end
            end
            info.strip! # Because this was formatted for humans
            [op_action, op_type, info]
          end
          private_class_method :parse_line

          def self.build_resource_info(resources)
            resources.map do |r|
              Chef::Util::DSC::ResourceInfo.new(r[:name], !r[:skipped], r[:logs])
            end
          end
          private_class_method :build_resource_info

        end
      end
    end
  end
end
