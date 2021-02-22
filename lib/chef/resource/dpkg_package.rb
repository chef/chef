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
    class DpkgPackage < Chef::Resource::Package
      unified_mode true

      provides :dpkg_package

      description "Use the **dpkg_package** resource to manage packages for the dpkg platform. When a package is installed from a local file, it must be added to the node using the **remote_file** or **cookbook_file** resources."

      property :source, [ String, Array, nil ],
        description: "The path to a package in the local file system."

      property :response_file, String,
        description: "The direct path to the file used to pre-seed a package.",
        desired_state: false

      property :response_file_variables, Hash,
        description: "A Hash of response file variables in the form of {'VARIABLE' => 'VALUE'}.",
        default: {}, desired_state: false
    end
  end
end
