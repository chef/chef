#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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
require "chef/resource/gem_package"

class Chef
  class Resource
    class ChefGem < Chef::Resource::Package::GemPackage
      resource_name :chef_gem

      property :gem_binary, default: "#{RbConfig::CONFIG['bindir']}/gem",
                            callbacks: {
                 "The chef_gem resource is restricted to the current gem environment, use gem_package to install to other environments." => proc { |v| v == "#{RbConfig::CONFIG['bindir']}/gem" },
               }
      property :compile_time, [ true, false, nil ], default: lazy { Chef::Config[:chef_gem_compile_time] }, desired_state: false

      def after_created
        # Chef::Resource.run_action: Caveat: this skips Chef::Runner.run_action, where notifications are handled
        # Action could be an array of symbols, but probably won't (think install + enable for a package)
        if compile_time.nil?
          Chef.log_deprecation "#{self} chef_gem compile_time installation is deprecated"
          Chef.log_deprecation "#{self} Please set `compile_time false` on the resource to use the new behavior."
          Chef.log_deprecation "#{self} or set `compile_time true` on the resource if compile_time behavior is required."
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
