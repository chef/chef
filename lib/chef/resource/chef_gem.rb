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

require_relative "package"
require_relative "gem_package"
require_relative "../dist"

class Chef
  class Resource
    # Use the chef_gem resource to install a gem only for the instance of Ruby that is dedicated to the chef-client.
    # When a gem is installed from a local file, it must be added to the node using the remote_file or cookbook_file
    # resources.
    #
    # The chef_gem resource works with all of the same properties and options as the gem_package resource, but does not
    # accept the gem_binary property because it always uses the CurrentGemEnvironment under which the chef-client is
    # running. In addition to performing actions similar to the gem_package resource, the chef_gem resource does the
    # following:
    #  - Runs its actions immediately, before convergence, allowing a gem to be used in a recipe immediately after it is
    #    installed
    #  - Runs Gem.clear_paths after the action, ensuring that gem is aware of changes so that it can be required
    #    immediately after it is installed
    class ChefGem < Chef::Resource::Package::GemPackage
      resource_name :chef_gem

      property :gem_binary, default: "#{RbConfig::CONFIG['bindir']}/gem", default_description: "Chef's built-in gem binary.",
                            description: "The path of a gem binary to use for the installation. By default, the same version of Ruby that is used by the #{Chef::Dist::CLIENT} will be installed.",
                            callbacks: {
                 "The chef_gem resource is restricted to the current gem environment, use gem_package to install to other environments." => proc { |v| v == "#{RbConfig::CONFIG['bindir']}/gem" },
               }
      property :compile_time, [TrueClass, FalseClass],
               description: "Controls the phase during which a gem is installed on a node. Set to 'true' to install a gem while the resource collection is being built (the 'compile phase'). Set to 'false' to install a gem while the #{Chef::Dist::CLIENT} is configuring the node (the 'converge phase').",
               default: false, desired_state: false

      # force the resource to compile time if the compile time property has been set
      #
      # @return [void]
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
