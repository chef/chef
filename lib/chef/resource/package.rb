#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
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

require_relative "../resource"

class Chef
  class Resource
    class Package < Chef::Resource
      provides :package, target_mode: true
      target_mode support: :full

      description "Use the **package** resource to manage packages. When the package is" \
                  " installed from a local file (such as with RubyGems, dpkg, or RPM" \
                  " Package Manager), the file must be added to the node using the remote_file" \
                  " or cookbook_file resources.\n\nThis resource is the base resource for" \
                  " several other resources used for package management on specific platforms." \
                  " While it is possible to use each of these specific resources, it is" \
                  " recommended to use the package resource as often as possible."

      default_action :install
      allowed_actions :install, :upgrade, :remove, :purge, :reconfig, :lock, :unlock

      def initialize(name, *args)
        # We capture name here, before it gets coerced to name
        package_name name
        super
      end

      property :package_name, [ String, Array ],
        description: "An optional property to set the package name if it differs from the resource block's name.",
        identity: true

      property :version, [ String, Array ],
        description: "The version of a package to be installed or upgraded."

      property :options, [ String, Array ],
        description: "One (or more) additional command options that are passed to the command.",
        coerce: proc { |x| x.is_a?(String) ? x.shellsplit : x }

      property :source, String,
        description: "The optional path to a package on the local file system.",
        desired_state: false

      property :timeout, [ String, Integer ],
        description: "The amount of time (in seconds) to wait before timing out.",
        desired_state: false

      property :environment, Hash,
        introduced: "19.0",
        description: "A Hash of environment variables in the form of {'ENV_VARIABLE' => 'VALUE'} to be set before running the command.",
        desired_state: false

    end
  end
end
