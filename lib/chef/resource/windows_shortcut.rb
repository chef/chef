#
# Author:: Doug MacEachern <dougm@vmware.com>
# Copyright:: 2010-2018, VMware, Inc.
# Copyright:: Copyright (c) Chef Software Inc.
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
    class WindowsShortcut < Chef::Resource
      unified_mode true

      provides(:windows_shortcut) { true }

      description "Use the **windows_shortcut** resource to create shortcut files on Windows."
      introduced "14.0"
      examples <<~DOC
      **Create a shortcut with a description**:

      ```ruby
      windows_shortcut 'C:\\shortcut_dir.lnk' do
        target 'C:\\original_dir'
        description 'Make a shortcut to C:\\original_dir'
      end
      ```
      DOC

      property :shortcut_name, String,
        description: "An optional property to set the shortcut name if it differs from the resource block's name.",
        name_property: true

      property :target, String,
        description: "The destination that the shortcut links to."

      property :arguments, String,
        description: "Arguments to pass to the target when the shortcut is executed."

      property :description, String,
        description: "The description of the shortcut"

      property :cwd, String,
        description: "Working directory to use when the target is executed."

      property :iconlocation, String,
        description: "Icon to use for the shortcut. Accepts the format of `path, index`, where index is the icon file to use. See Microsoft's [documentation](https://msdn.microsoft.com/en-us/library/3s9bx7at.aspx) for details"

      load_current_value do |new_resource|
        require "win32ole" if RUBY_PLATFORM.match?(/mswin|mingw32|windows/)

        link = WIN32OLE.new("WScript.Shell").CreateShortcut(new_resource.shortcut_name)
        name new_resource.shortcut_name
        target(link.TargetPath)
        arguments(link.Arguments)
        description(link.Description)
        cwd(link.WorkingDirectory)
        iconlocation(link.IconLocation)
      end

      action :create, description: "Create or modify a Windows shortcut." do
        converge_if_changed do
          converge_by "creating shortcut #{new_resource.shortcut_name}" do
            link = WIN32OLE.new("WScript.Shell").CreateShortcut(new_resource.shortcut_name)
            link.TargetPath = new_resource.target unless new_resource.target.nil?
            link.Arguments = new_resource.arguments unless new_resource.arguments.nil?
            link.Description = new_resource.description unless new_resource.description.nil?
            link.WorkingDirectory = new_resource.cwd unless new_resource.cwd.nil?
            link.IconLocation = new_resource.iconlocation unless new_resource.iconlocation.nil?
            # ignoring: WindowStyle, Hotkey
            link.Save
          end
        end
      end
    end
  end
end
