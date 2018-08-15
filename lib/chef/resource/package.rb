#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
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

require "chef/resource"

class Chef
  class Resource
    class Package < Chef::Resource
      resource_name :package

      description "Use the package resource to manage packages. When the package is"\
                  " installed from a local file (such as with RubyGems, dpkg, or RPM"\
                  " Package Manager), the file must be added to the node using the remote_file"\
                  " or cookbook_file resources.\n\nThis resource is the base resource for"\
                  " several other resources used for package management on specific platforms."\
                  " While it is possible to use each of these specific resources, it is"\
                  " recommended to use the package resource as often as possible."

      default_action :install
      allowed_actions :install, :upgrade, :remove, :purge, :reconfig, :lock, :unlock

      def initialize(name, *args)
        # We capture name here, before it gets coerced to name
        package_name name
        super
      end

      property :package_name, [ String, Array ], identity: true

      property :version, [ String, Array ]
      property :options, [ String, Array ], coerce: proc { |x| x.is_a?(String) ? x.shellsplit : x }
      property :response_file, String, desired_state: false
      property :response_file_variables, Hash, default: lazy { {} }, desired_state: false
      property :source, String, desired_state: false
      property :timeout, [ String, Integer ], desired_state: false

    end
  end
end
