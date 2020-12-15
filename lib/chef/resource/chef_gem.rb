#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) Chef Software Inc.
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
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class ChefGem < Chef::Resource::Package::GemPackage
      unified_mode true
      provides :chef_gem

      description <<~DESC
        Use the **chef_gem** resource to install a gem only for the instance of Ruby that is dedicated to the #{ChefUtils::Dist::Infra::CLIENT}.
        When a gem is installed from a local file, it must be added to the node using the **remote_file** or **cookbook_file** resources.

        The **chef_gem** resource works with all of the same properties and options as the **gem_package** resource, but does not
        accept the `gem_binary` property because it always uses the `CurrentGemEnvironment` under which the `#{ChefUtils::Dist::Infra::CLIENT}` is
        running. In addition to performing actions similar to the **gem_package** resource, the **chef_gem** resource does the
        following:
        - Runs its actions immediately, before convergence, allowing a gem to be used in a recipe immediately after it is installed.
        - Runs `Gem.clear_paths` after the action, ensuring that gem is aware of changes so that it can be required immediately after it is installed.

        Warning: The **chef_gem** and **gem_package** resources are both used to install Ruby gems. For any machine on which #{ChefUtils::Dist::Infra::PRODUCT} is
        installed, there are two instances of Ruby. One is the standard, system-wide instance of Ruby and the other is a dedicated instance that is
        available only to #{ChefUtils::Dist::Infra::PRODUCT}.
        Use the **chef_gem** resource to install gems into the instance of Ruby that is dedicated to #{ChefUtils::Dist::Infra::PRODUCT}.
        Use the **gem_package** resource to install all other gems (i.e. install gems system-wide).
      DESC

      examples <<~EXAMPLES
        **Compile time vs. converge time installation of gems**

        To install a gem while #{ChefUtils::Dist::Infra::PRODUCT} is configuring the node (the converge phase), set the `compile_time` property to `false`:
        ```ruby
        chef_gem 'loofah' do
          compile_time false
          action :install
        end
        ```

        To install a gem while the resource collection is being built (the compile phase), set the `compile_time` property to `true`:
        ```ruby
        chef_gem 'loofah' do
          compile_time true
          action :install
        end
        ```

        **Install MySQL gem into #{ChefUtils::Dist::Infra::PRODUCT}***
        ```ruby
        apt_update

        build_essential 'install compilation tools' do
          compile_time true
        end

        chef_gem 'mysql'
        ```
      EXAMPLES

      property :package_name, String,
        description: "An optional property to set the package name if it differs from the resource block's name.",
        identity: true

      property :version, String,
        description: "The version of a package to be installed or upgraded."

      property :gem_binary, String,
        default: "#{RbConfig::CONFIG["bindir"]}/gem",
        default_description: "The `gem` binary included with #{ChefUtils::Dist::Infra::PRODUCT}.",
        description: "The path of a gem binary to use for the installation. By default, the same version of Ruby that is used by #{ChefUtils::Dist::Infra::PRODUCT} will be used.",
        callbacks: {
          "The `chef_gem` resource is restricted to the current gem environment, use `gem_package` to install to other environments." =>
            proc { |v| v == "#{RbConfig::CONFIG["bindir"]}/gem" },
        }
    end
  end
end
