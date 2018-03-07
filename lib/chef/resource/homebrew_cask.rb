#
# Author:: Joshua Timberman (<jtimberman@chef.io>)
# Author:: Graeme Mathieson (<mathie@woss.name>)
#
# Copyright:: 2011-2018, Chef Software, Inc.
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

require "chef/resource"
require "chef/mixin/homebrew_user"

class Chef
  class Resource
    class HomebrewCask < Chef::Resource
      resource_name :homebrew_cask
      provides :homebrew_cask

      description ""
      introduced "14.0"

      include Chef::Mixin::HomebrewUser

      property :name, String,
               regex: %r{^[\w/-]+$},
               name_property: true

      property :options, String

      property :install_cask, [true, false],
               default: true

      action :install do
        homebrew_tap "caskroom/cask" if new_resource.install_cask

        declare_resource(:execute, "installing cask #{new_resource.name}") do
          command "/usr/local/bin/brew cask install #{new_resource.name} #{new_resource.options}"
          user find_homebrew_uid
          environment lazy { { "HOME" => ::Dir.home(find_homebrew_uid), "USER" => find_homebrew_uid } }
          not_if { casked? }
        end
      end

      action :uninstall do
        homebrew_tap "caskroom/cask" if new_resource.install_cask

        declare_resource(:execute, "uninstalling cask #{new_resource.name}") do
          command "/usr/local/bin/brew cask uninstall #{new_resource.name}"
          user find_homebrew_uid
          environment lazy { { "HOME" => ::Dir.home(find_homebrew_uid), "USER" => find_homebrew_uid } }
          only_if { casked? }
        end
      end

      action_class do
        alias_method :action_cask, :action_install
        alias_method :action_uncask, :action_uninstall

        def casked?
          unscoped_name = new_resource.name.split("/").last
          shell_out("/usr/local/bin/brew cask list 2>/dev/null", user: find_homebrew_uid).stdout.split.include?(unscoped_name)
        end
      end
    end
  end
end
