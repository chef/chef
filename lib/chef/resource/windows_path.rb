#
# Author:: Nimisha Sharad (<nimisha.sharad@msystechnologies.com>)
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

require_relative "../mixin/windows_env_helper" if ChefUtils.windows?
require_relative "../mixin/wide_string"
require_relative "../resource"

class Chef
  class Resource
    class WindowsPath < Chef::Resource
      unified_mode true

      provides(:windows_path) { true }

      description "Use the **windows_path** resource to manage the path environment variable on Microsoft Windows."
      introduced "13.4"
      examples <<~DOC
      **Add Sysinternals to the system path**:

      ```ruby
      windows_path 'C:\\Sysinternals' do
        action :add
      end
      ```

      **Remove 7-Zip from the system path**:

      ```ruby
      windows_path 'C:\\7-Zip' do
        action :remove
      end
      ```
      DOC

      allowed_actions :add, :remove
      default_action :add

      property :path, String,
        description: "An optional property to set the path value if it differs from the resource block's name.",
        name_property: true

      action_class do
        include Chef::Mixin::WindowsEnvHelper if ChefUtils.windows?

        def load_current_resource
          @current_resource = Chef::Resource::WindowsPath.new(new_resource.name)
          @current_resource.path(new_resource.path)
          @current_resource
        end
      end

      action :add, description: "Add an item to the system path." do
        # The windows Env provider does not correctly expand variables in
        # the PATH environment variable. Ruby expects these to be expanded.
        #
        path = expand_path(new_resource.path)
        env "path" do
          action :modify
          delim ::File::PATH_SEPARATOR
          value path.tr("/", "\\")
        end
      end

      action :remove, description: "Remove an item from the system path." do
        # The windows Env provider does not correctly expand variables in
        # the PATH environment variable. Ruby expects these to be expanded.
        #
        path = expand_path(new_resource.path)
        env "path" do
          action :delete
          delim ::File::PATH_SEPARATOR
          value path.tr("/", "\\")
        end
      end
    end
  end
end
