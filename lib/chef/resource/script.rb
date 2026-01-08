#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "execute"

class Chef
  class Resource
    class Script < Chef::Resource::Execute

      provides :script, target_mode: true
      target_mode support: :full,
        description: "Needs interpreter installed on target node."

      identity_attr :name

      description "Use the **script** resource to execute scripts using a specified interpreter, such as Bash, csh, Perl, Python, or Ruby." \
                  " This resource may also use any of the actions and properties that are available to the **execute** resource. Commands" \
                  " that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the" \
                  " environment in which they are run. Use `not_if` and `only_if` to guard this resource for idempotence."

      def initialize(name, run_context = nil)
        super
        @command = nil
        @default_guard_interpreter = :default
      end

      # FIXME: remove this and use an execute sub-resource instead of inheriting from Execute
      def command(arg = nil)
        super
        unless arg.nil?
          raise Chef::Exceptions::Script, "Do not use the command property on a #{resource_name} resource, use the 'code' property instead."
        end
      end

      property :code, String, required: true,
        description: "A quoted string of code to be executed."

      property :interpreter, String

      property :flags, String,
        description: "One or more command line flags that are passed to the interpreter when a command is invoked."
    end
  end
end
