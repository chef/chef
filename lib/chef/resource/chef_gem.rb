#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright 2012-2017, Chef Software Inc.
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
      property :compile_time, [ true, false ], default: false, desired_state: false

      def after_created
        if compile_time
          Array(action).each do |action|
            run_action(action)
          end
          Gem.clear_paths
        end
      end
    end
  end
end
