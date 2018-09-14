#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software, Inc.
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
    class DpkgPackage < Chef::Resource::Package
      resource_name :dpkg_package
      provides :dpkg_package

      description "Use the dpkg_package resource to manage packages for the dpkg platform. When a package is installed from a local file, it must be added to the node using the remote_file or cookbook_file resources."

      property :source, [ String, Array, nil ],
               description: "The path to a package in the local file system."
    end
  end
end
