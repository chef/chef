#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

      allowed_actions :install, :upgrade, :remove, :purge, :reconfig

      # windows can't take Array options yet
      property :options, String,
                description: "One (or more) additional options that are passed to the command."

      property :package_name, [String, Array],
                description: "The name of the package. Default value: the name of the resource block.",
                coerce: proc { |x| [x].flatten }

      property :version, [String, Array],
                description: "The version of a package to be installed or upgraded.",
                coerce: proc { |x| [x].flatten }

      property :returns, [Integer, Array],
                description: "The exit code(s) returned a chocolatey package that indicate success.",
                default: [ 0 ], desired_state: false,
                introduced: "12.18"
    end
  end
end
