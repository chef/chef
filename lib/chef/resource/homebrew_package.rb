#
# Author:: Joshua Timberman (<joshua@chef.io>)
# Author:: Graeme Mathieson (<mathie@woss.name>)
#
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../provider/package"
require_relative "package"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class HomebrewPackage < Chef::Resource::Package
      unified_mode true

      provides :homebrew_package
      provides :package, os: "darwin"

      description "Use the **homebrew_package** resource to manage packages for the macOS platform. Note: Starting with #{ChefUtils::Dist::Infra::PRODUCT} 16 the homebrew resource now accepts an array of packages for installing multiple packages at once."
      introduced "12.0"
      examples <<~DOC
      **Install a package**:

      ```ruby
      homebrew_package 'git'
      ```

      **Install multiple packages at once**:

      ```ruby
      homebrew_package %w(git fish ruby)
      ```

      **Specify the Homebrew user with a UUID**

      ```ruby
      homebrew_package 'git' do
        homebrew_user 1001
      end
      ```

      **Specify the Homebrew user with a string**:

      ```ruby
      homebrew_package 'vim' do
        homebrew_user 'user1'
      end
      ```
      DOC

      property :homebrew_user, [ String, Integer ],
        description: "The name or uid of the Homebrew owner to be used by #{ChefUtils::Dist::Infra::PRODUCT} when executing a command.\n\n#{ChefUtils::Dist::Infra::PRODUCT}, by default, will attempt to execute a Homebrew command as the owner of the `/usr/local/bin/brew` executable. If that executable does not exist, #{ChefUtils::Dist::Infra::PRODUCT} will attempt to find the user by executing `which brew`. If that executable cannot be found, #{ChefUtils::Dist::Infra::PRODUCT} will print an error message: `Could not find the 'brew' executable in /usr/local/bin or anywhere on the path.`.\n\nSet this property to specify the Homebrew owner for situations where Chef Infra Client cannot automatically detect the correct owner.'"

    end
  end
end
