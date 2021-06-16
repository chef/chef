#
# Author:: Adam Edwards (<adamed@chef.io>)
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
require_relative "windows_script"

class Chef
  class Resource
    class PowershellScript < Chef::Resource::WindowsScript
      unified_mode true

      set_guard_inherited_attributes(:interpreter)

      provides :powershell_script, os: "windows"

      description <<~DESC
        Use the **powershell_script** resource to execute a script using the Windows PowerShell interpreter, much like how the script and script-based resources **bash**, **csh**, **perl**, **python**, and **ruby** are used. The **powershell_script** resource is specific to the Microsoft Windows platform, but may use both the Windows PowerShell interpreter or the PowerShell Core (pwsh) interpreter as of Chef Infra Client 16.6 and later.

        The **powershell_script** resource creates and executes a temporary file rather than running the command inline. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use `not_if` and `only_if` conditionals to guard this resource for idempotence.
      DESC

      property :flags, String,
        description: "A string that is passed to the Windows PowerShell command"

      property :interpreter, String,
        default: "powershell",
        equal_to: %w{powershell pwsh},
        description: "The interpreter type, `powershell` or `pwsh` (PowerShell Core)"

      property :convert_boolean_return, [true, false],
        default: false,
        description: <<~DESC
          Return `0` if the last line of a command is evaluated to be true or to return `1` if the last line is evaluated to be false.

          When the `guard_interpreter` common attribute is set to `:powershell_script`, a string command will be evaluated as if this value were set to `true`. This is because the behavior of this attribute is similar to the value of the `"$?"` expression common in UNIX interpreters. For example, this:

          ```ruby
          powershell_script 'make_safe_backup' do
            guard_interpreter :powershell_script
            code 'cp ~/data/nodes.json ~/data/nodes.bak'
            not_if 'test-path ~/data/nodes.bak'
          end
          ```

          is similar to:
          ```ruby
          bash 'make_safe_backup' do
            code 'cp ~/data/nodes.json ~/data/nodes.bak'
            not_if 'test -e ~/data/nodes.bak'
          end
          ```
        DESC

      def initialize(*args)
        super
        @default_guard_interpreter = resource_name
      end

      # Allow callers evaluating guards to request default
      # attribute values. This is needed to allow
      # convert_boolean_return to be true in guard context by default,
      # and false by default otherwise. When this mode becomes the
      # default for this resource, this method can be removed since
      # guard context and recipe resource context will have the
      # same behavior.
      def self.get_default_attributes
        { convert_boolean_return: true }
      end
    end
  end
end
