# Author:: Dheeraj Dubey(dheeraj.dubey@msystechnologies.com)
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
    class PowershellPackage < Chef::Resource::Package

      provides :powershell_package

      description "Use the **powershell_package** resource to install and manage packages via the PowerShell Package Manager for the Microsoft Windows platform. The powershell_package resource requires administrative access, and a source must be configured in the PowerShell Package Manager via the powershell_package_source resource."
      introduced "12.16"

      allowed_actions :install, :remove

      property :package_name, [String, Array],
        description: "The name of the package. Default value: the name of the resource block.",
        coerce: proc { |x| [x].flatten }

      property :version, [String, Array],
        description: "The version of a package to be installed or upgraded.",
        coerce: proc { |x| [x].flatten }

      property :source, String,
        description: "Specify the source of the package.",
        introduced: "14.0"

      property :skip_publisher_check, [true, false],
        description: "Skip validating module author.",
        default: false, introduced: "14.3", desired_state: false

      property :allow_clobber,  [TrueClass, FalseClass],
        description: "Overrides warning messages about installation conflicts about existing commands on a computer.",
        default: false, introduced: "18.5"

    end
  end
end
