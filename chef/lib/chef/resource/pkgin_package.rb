#
# Author:: Sean OMeara (<someara@opscode.com>)
# Copyright:: 2012, Opscode, Inc.
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

#require 'chef/resource/package'
#require 'chef/provider/package/pkgin'

class Chef
  class Resource
    class PkginPackage < Chef::Resource::Package
      def initialize(name, run_context = nil)
        super(name, run_context)
        @resource_name = :pkgin_package
        @provider      = Chef::Provider::Package::Pkgin
        @allowed_actions = [ :install, :remove, :upgrade]
      end
    end
  end
end
