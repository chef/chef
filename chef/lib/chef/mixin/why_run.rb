#
# Author:: Dan DeLeo ( <dan@opscode.com> )
# Author:: Marc Paradise ( <marc@opscode.com> )
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

class Chef
  module Mixin
    module WhyRun
      class ConvergeActions
        attr_reader :actions

        def initialize
          @actions = []
        end

        def add_action(descriptions, &block)
          @actions << [descriptions, block]
        end

        def empty?
          @actions.empty?
        end

        def converge!
          @actions.each do |descriptions, block|
            # TODO: probably should get this out of the run context instead of making it really global?
            if Chef::Config[:why_run]
              # TODO: legit logging here
              Array(descriptions).each do |description|
                puts "WHY RUN: #{description}"
              end
            else
              block.call
            end
          end
        end
      end

      class ResourceRequirements
        class Assertion
          class AssertionFailure < RuntimeError
          end

          def initialize
            @assertion_proc = nil
            @failure_message = nil
            @whyrun_message = nil
            @resource_modifier = nil
            @exception_type = AssertionFailure
          end

          def assertion(&assertion_proc)
            @assertion_proc = assertion_proc
          end

          def failure_message(*args)
           case args.size
           when 1
             @failure_message = args[0]
           when 2
             @exception_type, @failure_message = args[0], args[1]
           else
             raise ArgumentError, "#{self.class}#failure_message takes 1 or 2 arguments, you gave #{args.inspect}"
           end
          end

          def whyrun(message, &resource_modifier)
            @whyrun_message = message
            @resource_modifier = resource_modifier
          end

          def run
            if !@assertion_proc.call
              # TODO: figure out how we want to turn why run on/off...
              if Chef::Config[:why_run] && @whyrun_message
                # TODO: real logging
                puts "WHY RUN: #{@failure_message}"
                puts "WHY RUN: #{@whyrun_message}"
                @resource_modifier.call if @resource_modifier
              else
                raise @exception_type, @failure_message
              end
            end
          end
        end

        def initialize
          @assertions = Hash.new {|h,k| h[k] = [] }
        end

        def assert(*actions)
          assertion = Assertion.new
          yield assertion
          actions.each {|action| @assertions[action] << assertion }
        end

        def run(action)
          @assertions[action].each {|a| a.run }
        end
      end
    end
  end
end
