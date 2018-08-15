#
# Author:: Doug MacEachern <dougm@vmware.com>
# Copyright:: 2010-2018, VMware, Inc.
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

require "chef/resource"

class Chef
  class Resource
    class WindowsShortcut < Chef::Resource
      resource_name :windows_shortcut
      provides(:windows_shortcut) { true }

      description "Use the windows_shortcut resource to create shortcut files on Windows"
      introduced "14.0"

      property :shortcut_name, String,
               description: "The name for the shortcut if it differs from the resource name.",
               name_property: true

      property :target, String,
               description: "Where the shortcut links to."

      property :arguments, String,
               description: "Arguments to pass to the target when the shortcut is executed."

      property :description, String,
               description: "The description of the shortcut"

      property :cwd, String,
               description: "Working directory to use when the target is executed."

      property :iconlocation, String,
               description: "Icon to use for the shortcut, in the format of 'path, index'. Index is the icon file to use. See https://msdn.microsoft.com/en-us/library/3s9bx7at.aspx for details"

      load_current_value do |desired|
        require "win32ole" if RUBY_PLATFORM =~ /mswin|mingw32|windows/

        link = WIN32OLE.new("WScript.Shell").CreateShortcut(desired.shortcut_name)
        name desired.shortcut_name
        target(link.TargetPath)
        arguments(link.Arguments)
        description(link.Description)
        cwd(link.WorkingDirectory)
        iconlocation(link.IconLocation)
      end

      action :create do
        description "Create or modify a Windows shortcut."

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
