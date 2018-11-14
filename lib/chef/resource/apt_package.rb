#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "chef/resource/package"

class Chef
  class Resource
    class AptPackage < Chef::Resource::Package
      resource_name :apt_package
      provides :package, platform_family: "debian"

      description "Use the apt_package resource to manage packages on Debian and Ubuntu platforms."

      property :default_release, String,
               description: "The default release. For example: stable.",
               desired_state: false

      property :overwrite_config_files, [TrueClass, FalseClass],
               introduced: "14.0",
               description: "Overwrite existing configuration files with those supplied by the package, if prompted by APT.",
               default: false

    end
  end
end
