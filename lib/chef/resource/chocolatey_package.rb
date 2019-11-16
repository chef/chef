#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2019, Chef Software Inc.
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
      resource_name :chocolatey_package
      provides :chocolatey_package

      description "Use the chocolatey_package resource to manage packages using Chocolatey on the Microsoft Windows platform."
      introduced "12.7"
      examples <<~DOC
        Install a Chocolatey package
        ```ruby
        chocolatey_package 'name of package' do
          action :install
        end
        ```

        Install a package with options with Chocolatey's ``--checksum`` option
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

      property :version, [String, Array],
        description: "The version of a package to be installed or upgraded.",
        coerce: proc { |x| [x].flatten }

      # In the choco if we have the feature useEnhancedExitCodes turned on, then choco will provide enhanced exit codes(2: no results).
      # Choco exit codes https://chocolatey.org/docs/commandsinfo#exit-codes
      property :returns, [Integer, Array],
        description: "The exit code(s) returned a chocolatey package that indicate success.",
        default: [ 0, 2 ], desired_state: false,
        introduced: "12.18"
    end
  end
end
