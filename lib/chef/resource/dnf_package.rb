#
# Author:: AJ Christensen (<aj@chef.io>)
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
    class DnfPackage < Chef::Resource::Package
      extend Chef::Mixin::Which

      resource_name :dnf_package

      provides :package, os: "linux", platform_family: %w{rhel fedora} do
        which("dnf")
      end

      provides :dnf_package

      # Install a specific arch
      # FIXME: not implemented
      property :arch, [ String, Array ]

      # FIXME: dnf install should downgrade, so this should warn that users do not need to use it any more?
      property :allow_downgrade, [ true, false ], default: false
    end
  end
end
