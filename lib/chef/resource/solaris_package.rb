#
# Author:: Toomas Pelberg (<toomasp@gmx.net>)
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'chef/resource/package'
require 'chef/provider/package/solaris'

class Chef
  class Resource
    class SolarisPackage < Chef::Resource::Package
      provides :package, os: "solaris2", platform_family: "nexentacore"
      provides :package, os: "solaris2", platform_family: "solaris2" do |node|
        # on >= Solaris 11 we default to IPS packages instead
        node[:platform_version].to_f <= 5.10
      end
    end
  end
end
