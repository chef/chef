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
    class ChocolateyPackage < Chef::Resource::Package

      provides :chocolatey_package

      description "Use the **chocolatey_package** resource to manage packages using the Chocolatey package manager on the Microsoft Windows platform. Note: The Chocolatey package manager is not installed on Windows by default. You will need to install it prior to using this resource by adding the [chocolatey cookbook](https://supermarket.chef.io/cookbooks/chocolatey/) to your node's run list. Warning: The **chocolatey_package** resource must be specified as `chocolatey_package` and cannot be shortened to `package` in a recipe."
      introduced "12.7"
      examples <<~DOC
        **Install a Chocolatey package**:

        ```ruby
        chocolatey_package 'name of package' do
          action :install
        end
        ```

        **Install a package with options with Chocolatey's `--checksum` option**:

        ```ruby
        chocolatey_package 'name of package' do
          options '--checksum 1234567890'
          action :install
        end
        ```
      DOC

      allowed_actions :install, :upgrade, :remove, :purge, :reconfig

      # windows can't take Array options yet
      property :options, [String, Array],
        description: "One (or more) additional options that are passed to the command."

      property :list_options, String,
        introduced: "15.3",
        description: "One (or more) additional list options that are passed to the command."

      property :user, String,
        introduced: "15.3",
        description: "The username to authenticate feeds."

      property :password, String,
        introduced: "15.3",
        description: "The password to authenticate to the source."

      property :package_name, [String, Array],
        description: "The name of the package. Default value: the name of the resource block.",
        coerce: proc { |x| [x].flatten }

      property :bulk_query, [TrueClass, FalseClass],
        description: "Bulk query the chocolatey server?  This will cause the provider to list all packages instead of doing individual queries.",
        default: false

      property :use_choco_list, [TrueClass, FalseClass],
        description: "Use choco list for getting the locally installed packages, rather than reading the nupkg database directly?  This defaults to false, since reading the package data is faster.",
        default: false

      property :version, [String, Array],
        description: "The version of a package to be installed or upgraded.",
        coerce: proc { |x| [x].flatten }

      # In the choco if we have the feature useEnhancedExitCodes turned on, then choco will provide enhanced exit codes(2: no results).
      # Choco exit codes https://docs.chocolatey.org/en-us/choco/commands/info#exit-codes
      property :returns, [Integer, Array],
        description: "The exit code(s) returned by the `choco` command that indicate a successful action. See [Chocolatey Exit Codes](https://docs.chocolatey.org/en-us/choco/commands/info#exit-codes) for a complete list of exit codes used by Chocolatey.",
        default: [ 0, 2 ], desired_state: false,
        introduced: "12.18"
    end
  end
end
