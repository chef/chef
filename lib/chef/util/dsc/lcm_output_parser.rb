#
# Author:: Jay Mundrawala (<jdm@getchef.com>)
#
# Copyright:: 2014, Chef Software, Inc.
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

class Chef
  class Util
    class DSC
      class LocalConfigurationManager
        class DscResourceInfo
          # The name is the text following [Start Set]
          attr_reader :name

          # A list of all log messages between [Start Set] and [End Set].
          # Each line is an element in the list.
          attr_reader :change_log

          def initialize(name, sets, change_log)
            @name = name
            @sets = sets
            @change_log = change_log || []
          end

          def changes_state?
            @sets
          end
        end
        module Parser
          class Operation
            attr_reader :op_type
            attr_reader :resources
            attr_reader :info
            attr_reader :sets
            attr_reader :tests

            def initialize(op_type, info)
              @op_type = op_type
              @info = []
              @sets = []
              @tests = []
              @resources = []
              add_info(info)
            end

            def add_info(info)
              @info << info
            end

            def add_set(set)
              raise LCMOutputParseException, "add_set is not allowed in this context. Found #{@op_type}" unless [:resource, :set]
              @sets << set
            end

            def add_test(test)
              raise LCMOutputParseException, "add_test is not allowed in this context. Found #{@op_type}" unless [:resource, :set]
              @tests << test
            end

            def add_resource(resource)
              raise LCMOutputParseException, 'add_resource is only allowed to be added to the set op_type' unless @op_type == :set
              @resources << resource
            end
          end

          # Parses the output from LCM and returns a list of DscResourceInfo objects
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
          #     DscResourceInfo.new(
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
            return [] unless lcm_output

            stack = Array.new
            popped_op = nil
            lcm_output.lines.each do |line|
              op_action, op_type, info = parse_line(line)
              info.strip! # Because this was formatted for humans

              # The rules:
              # - For each `start` action, there must be a matching `end` action
              # - `skip` actions do not not do anything (They don't add to the stack)
              case op_action
              when :start
                new_op = Operation.new(op_type, info)
                case op_type
                when :set
                  stack[-1].add_set(new_op) if stack[-1]
                when :test
                  stack[-1].add_test(new_op)
                when :resource
                  stack[-1].add_resource(new_op)
                else
                  Chef::Log.warn("Unknown op_action #{op_action}: Read line #{line}")
                end
                stack.push(new_op)
              when :end
                popped_op = stack.pop
                popped_op.add_info(info)
                if popped_op.op_type != op_type
                  raise LCMOutputParseException, "Unmatching end for op_type. Expected op_type=#{op_type}, found op_type=#{popped_op.op_type}"
                end
              when :skip
                # We don't really have anything to do here
              when :info
                stack[-1].add_info(info) if stack[-1]
              else
                stack[-1].add_info(line) if stack[-1]
              end
            end

            op_to_resource_infos(popped_op)
          end

          def self.parse_line(line)
            if match = line.match(/^.*?:.*?:\s*LCM:\s*\[(.*?)\](.*)/)
                # If the line looks like
                # x: [y]: LCM: [op_action op_type] message
                # extract op_action, op_type, and message
                operation, info = match.captures
                op_action, op_type = operation.strip.split(' ').map {|m| m.downcase.to_sym}
            else
              # If the line looks like
              # x: [y]: message
              # extract message
              match = line.match(/^.*?:.*?: \s+(.*)/)
              op_action = op_type = :info
              info = match.captures[0]
            end
            info.strip! # Because this was formatted for humans
            return [op_action, op_type, info]
          end
          private_class_method :parse_line

          def self.op_to_resource_infos(op)
            resources = op ? op.resources : []

            resources.map do |r|
              name = r.info[0]
              sets = r.sets.length > 0
              change_log = r.sets[-1].info if sets
              DscResourceInfo.new(name, sets, change_log)
            end
          end
          private_class_method :op_to_resource_infos

        end
      end
    end
  end
end
