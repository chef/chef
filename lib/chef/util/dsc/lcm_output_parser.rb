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
          attr_reader :name
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
              raise RuntimeError, "add_set is not allowed in this context. Found #{@op_type}" unless [:resource, :set]
              @sets << set
            end

            def add_test(test)
              raise RuntimeError, "add_test is not allowed in this context. Found #{@op_type}" unless [:resource, :set]
              @tests << test
            end

            def add_resource(resource)
              raise RuntimeError, 'add_resource is only allowed to be added to the set op_type' unless @op_type == :set
              @resources << resource
            end
          end

          def self.parse(lcm_output)
            return [] unless lcm_output

            stack = Array.new
            popped_op = nil
            lcm_output.lines.each do |line|
              if match = line.match(/^.*?:.*?:\s*LCM:\s*\[(.*?)\](.*)/)
                operation, info = match.captures
                op_action, op_type = operation.strip.split(' ').map {|m| m.downcase.to_sym}
              else
                match = line.match(/^.*?:.*?: \s+(.*)/)
                op_action = op_type = :info
                info = match.captures[0]
              end
              info.strip!

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
                  # Warn ? Its fine as long as it pops off
                end
                stack.push(new_op)
              when :end
                popped_op = stack.pop
                popped_op.add_info(info)
                if popped_op.op_type != op_type
                  raise RuntimeError, "Unmatching end for op_type. Expected op_type=#{op_type}, found op_type=#{popped_op.op_type}"
                end
              when :skip
                # We don't really have anything to do here
              when :info
                stack[-1].add_info(info) if stack[-1]
              else
                # Keep calm and carry on
              end
            end

            resources = popped_op ? popped_op.resources : []

            resources.map do |r|
              name = r.info[0]
              sets = r.sets.length > 0
              change_log = r.sets[-1].info if sets
              DscResourceInfo.new(name, sets, change_log)
            end
          end
        end
      end
    end
  end
end
