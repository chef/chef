#
# Author:: Jason Williams (<williamsjj@digitar.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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
require 'chef/provider/package/ips'

class Chef
  class Resource
    class IpsPackage < ::Chef::Resource::Package
      def initialize(name, run_context = nil)
        super(name, run_context)
        @resource_name = :ips_package
        @provider      = Chef::Provider::Package::Ips
        @allowed_actions = [ :install, :remove, :upgrade ]
        @accept_license = false
      end

      def accept_license(arg=nil)
        set_or_return(
          :purge,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end
    end
  end
end
