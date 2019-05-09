#
# Author:: Paul Morton (<pmorton@biaprotect.com>)
# Copyright:: 2011-2018, Business Intelligence Associates, Inc.
# Copyright:: 2017-2018, Chef Software, Inc.
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

require_relative "../resource"

class Chef
  class Resource
    class WindowsAutorun < Chef::Resource
      resource_name :windows_auto_run
      provides(:windows_auto_run) { true }

      description "Use the windows_auto_run resource to set applications to run at login."
      introduced "14.0"

      property :program_name, String,
               description: "The name of the program to run at login if it differs from the resource block's name.",
               name_property: true

      property :path, String,
               coerce: proc { |x| x.tr("/", "\\") }, # make sure we have windows paths for the registry
               description: "The path to the program that will run at login. "

      property :args, String,
               description: "Any arguments to be used with the program."

      property :root, Symbol,
               description: "The registry root key to put the entry under.",
               equal_to: %i{machine user},
               default: :machine

      alias_method :program, :path

      action :create do
        description "Create an item to be run at login."

        data = "\"#{new_resource.path}\""
        data << " #{new_resource.args}" if new_resource.args

        registry_key registry_path do
          values [{
            name: new_resource.program_name,
            type: :string,
            data: data,
          }]
          action :create
        end
      end

      action :remove do
        description "Remove an item that was previously setup to run at login"

        registry_key registry_path do
          values [{
            name: new_resource.program_name,
            type: :string,
            data: "",
          }]
          action :delete
        end
      end

      action_class do
        # determine the full registry path based on the root property
        # @return [String]
        def registry_path
          { machine: "HKLM", user: "HKCU" }[new_resource.root] + \
            '\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run'
        end
      end
    end
  end
end
