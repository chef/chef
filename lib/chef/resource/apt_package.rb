#
# Author:: Adam Jacob (<adam@chef.io>)
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

require_relative "package"

class Chef
  class Resource
    class AptPackage < Chef::Resource::Package
      unified_mode true

      provides :apt_package, target_mode: true
      provides :package, platform_family: "debian", target_mode: true
      examples <<~DOC
      **Install a package using package manager**:

      ```ruby
      apt_package 'name of package' do
        action :install
      end
      ```

      **Install a package without specifying the default action**:

      ```ruby
      apt_package 'name of package'
      ```

      **Install multiple packages at once**:

      ```ruby
      apt_package %(package1 package2 package3)
      ```

      **Install without using recommend packages as a dependency**:

      ```ruby
      package 'apache2' do
        options '--no-install-recommends'
      end
      ```
      DOC

      description "Use the **apt_package** resource to manage packages on Debian and Ubuntu platforms."

      property :default_release, String,
        description: "The default release. For example: `stable`.",
        desired_state: false

      property :overwrite_config_files, [TrueClass, FalseClass],
        introduced: "14.0",
        description: "Overwrite existing configuration files with those supplied by the package, if prompted by APT.",
        default: false

      property :response_file, String,
        description: "The direct path to the file used to pre-seed a package.",
        desired_state: false

      property :response_file_variables, Hash,
        description: "A Hash of response file variables in the form of {'VARIABLE' => 'VALUE'}.",
        default: {}, desired_state: false

    end
  end
end
