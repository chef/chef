#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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
require 'chef/resource/gem_package'

class Chef
  class Resource
    class ChefGem < Chef::Resource::Package::GemPackage

      def initialize(name, run_context=nil)
        super
        @resource_name = :chef_gem
        @provider = Chef::Provider::Package::Rubygems
      end

      # The chef_gem resources is for installing gems to the current gem environment only for use by Chef cookbooks.
      def gem_binary(arg=nil)
        if arg
          raise ArgumentError, "The chef_gem resource is restricted to the current gem environment, use gem_package to install to other environments."
        end

        nil
      end
        
    end
  end
end
