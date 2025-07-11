#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com>)
# Copyright:: Copyright 2010-2016, Thomas Bishop
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
    class RpmPackage < Chef::Resource::Package

      provides :rpm_package, target_mode: true
      target_mode support: :full

      allowed_actions :install, :upgrade, :remove

      description "Use the **rpm_package** resource to manage packages using the RPM Package Manager."

      property :allow_downgrade, [ TrueClass, FalseClass ],
        description: "Allow downgrading a package to satisfy requested version requirements.",
        default: true,
        desired_state: false

      property :package_name, String,
        description: "An optional property to set the package name if it differs from the resource block's name.",
        identity: true

      property :version, String,
        description: "The version of a package to be installed or upgraded."

      property :environment, Hash,
        introduced: "19.0",
        description: "A Hash of environment variables in the form of {'ENV_VARIABLE' => 'VALUE'} to be set before running the command.",
        default: {}, desired_state: false
    end
  end
end
