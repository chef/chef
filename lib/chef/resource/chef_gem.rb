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
        @compile_time = Chef::Config[:chef_gem_compile_time]
        @gem_binary = RbConfig::CONFIG['bindir'] + "/gem"
      end

      # The chef_gem resources is for installing gems to the current gem environment only for use by Chef cookbooks.
      def gem_binary(arg=nil)
        if arg
          raise ArgumentError, "The chef_gem resource is restricted to the current gem environment, use gem_package to install to other environments."
        end

        @gem_binary
      end

      def compile_time(arg=nil)
        set_or_return(
          :compile_time,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def after_created
        # Chef::Resource.run_action: Caveat: this skips Chef::Runner.run_action, where notifications are handled
        # Action could be an array of symbols, but probably won't (think install + enable for a package)
        if compile_time.nil?
          Chef::Log.deprecation "#{self} chef_gem compile_time installation is deprecated"
          Chef::Log.deprecation "#{self} Please set `compile_time false` on the resource to use the new behavior."
          Chef::Log.deprecation "#{self} or set `compile_time true` on the resource if compile_time behavior is required."
        end

        if compile_time || compile_time.nil?
          Array(action).each do |action|
            self.run_action(action)
          end
          Gem.clear_paths
        end
      end
    end
  end
end
