#
# Author:: Adam Jacob (<adam@chef.io>)
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

require_relative "package"

class Chef
  class Resource
    class AptPackage < Chef::Resource::Package

      provides :apt_package, target_mode: true
      provides :package, platform_family: "debian", target_mode: true
      target_mode support: :full,
        introduced: "15.1",
        updated: "19.0",
        description: "Does not support the `response_file` property in Target Mode."

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
      apt_package %w(package1 package2 package3)
      ```

      **Install without using recommend packages as a dependency**:

      ```ruby
      package 'apache2' do
        options '--no-install-recommends'
      end
      ```

      **Prevent the apt_package resource from installing packages with pattern matching names**:

      By default, the apt_package resource will install the named package.
      If it can't find a package with the exact same name, it will treat the package name as regular expression string and match with any package that matches that regular expression.
      This may lead Chef Infra Client to install one or more packages with names that match that regular expression.

      In this example, `anchor_package_regex true` prevents the apt_package resource from installing matching packages if it can't find the `lua5.3` package.

      ```ruby
      apt_package 'lua5.3' do
        version '5.3.3-1.1ubuntu2'
        anchor_package_regex true
      end
      ```
      DOC

      description "Use the **apt_package** resource to manage packages on Debian, Ubuntu, and other platforms that use the APT package system."

      allowed_actions :install, :upgrade, :remove, :purge, :reconfig, :lock, :unlock

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

      property :anchor_package_regex, [TrueClass, FalseClass],
        introduced: "18.3",
        description: "A Boolean flag that indicates whether the package name, which can be a regular expression, must match the entire name of the package (true) or if the regular expression is allowed to match a subset of the name (false).",
        default: false

      property :environment, Hash,
        introduced: "19.0",
        description: "A Hash of environment variables in the form of {'ENV_VARIABLE' => 'VALUE'} to be set before running the command.",
        default: {}, desired_state: false
    end
  end
end
