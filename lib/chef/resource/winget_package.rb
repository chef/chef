#
# Author:: Joe Williams (<joe@joetify.com>)
# Copyright:: Copyright 2009-2016, Joe Williams
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

require_relative "package"

class Chef
  class Resource
    class WingetPackage < Chef::Resource::Package
      unified_mode true

      provides :winget_package
      provides :package, platform_family: "windows"

      description "Use the **winget_package** resource to add/update windows packages using WinGet."
      introduced "17.20"
      examples <<~DOC
      **Add a new package to a system**

      ```ruby
      winget_package 'Install 7zip' do
        package_name  7zip
        action :install
      end
      ```

      **Add multiple packages to a system**

      ```ruby
      winget_package 'Install 7zip' do
        package_name  ["7zip", "notepad", "foo"]
        package_version ["0.1.2", "5.4", "0.0.5"]
        action :install
      end
      ```

      **Add several packages on a system**

      ```ruby
      winget_package 'Install 7zip' do
        package_name  %[1Password MicroK8s]
        action :install
      end
      ```

      **Install a package from a custom source**

      ```ruby
      winget_package "Install 7zip from new source" do
        package_name  7zip
        source_name "my_package_source"
        scope 'User'
        location "C:\\Foo\\7Zip"
        options "-o, -q, -h"
        force true
        action :install
      end
      ```
      DOC

      property :package_name, [ String, Array ],
        description: "The name of one or more packages to be installed."

      property :package_version, [ String, Array ],
        description: "The version of one or more packages to be installed. The position of the version corresponds to the name specified in the package_name array."

      property :source_name, String,
        description: "The name of a custom installation source.",
        default: "winget"

      property :scope, String,
        description: "Install the package for the current user or the whole machine.",
        default: "user", equal_to: %w{user machine}

      property :location, String,
        description: "The location on the local system to install the package to. For example 'c:\\foo\\'."

      property :options, [ String, Array ],
        description: "Command line switches to pass to your package. In the form of ['-o', '-foo', '-bar', '-blat']."

      property :force, [TrueClass, FalseClass],
        description: "Tells WinGet to bypass hash-checking a package.",
        default: false
    end
  end
end