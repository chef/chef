#
# Author:: Joshua Timberman (<jtimberman@chef.io>)
# Author:: Dan Webb (<dan@webb-agile-solutions.ltd>)
#
# Copyright:: Copyright (c) Chef Software Inc.
# Copyright:: Copyright (c) Webb Agile Solutions Ltd.
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

require_relative "../resource"
require_relative "../mixin/homebrew_user"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class HomebrewUpdate < Chef::Resource
      include Chef::Mixin::HomebrewUser

      unified_mode true

      provides(:homebrew_update) { true }

      description "Use the **homebrew_update** resource to manage Homebrew repository updates on macOS."
      introduced "16.2"
      examples <<~DOC
        **Update the homebrew repository data at a specified interval**:
        ```ruby
        homebrew_update 'all platforms' do
          frequency 86400
          action :periodic
        end
        ```
        **Update the Homebrew repository at the start of a #{ChefUtils::Dist::Infra::PRODUCT} run**:
        ```ruby
        homebrew_update 'update'
        ```
      DOC

      # allow bare homebrew_update with no name
      property :name, String, default: ""

      property :frequency, Integer,
        description: "Determines how frequently (in seconds) Homebrew updates are made. Use this property when the `:periodic` action is specified.",
        default: 86_400

      default_action :periodic
      allowed_actions :update, :periodic

      action_class do
        BREW_STAMP_DIR = "/var/lib/homebrew/periodic".freeze
        BREW_STAMP = "#{BREW_STAMP_DIR}/update-success-stamp".freeze

        # Determines whether we need to run `homebrew update`
        #
        # @return [Boolean]
        def brew_up_to_date?
          ::File.exist?(BREW_STAMP) &&
            ::File.mtime(BREW_STAMP) > Time.now - new_resource.frequency
        end

        def do_update
          directory BREW_STAMP_DIR do
            recursive true
          end

          file BREW_STAMP do
            content "BREW::Update::Post-Invoke-Success\n"
            action :create_if_missing
          end

          execute "brew update" do
            command %w{brew update}
            default_env true
            user find_homebrew_uid
            notifies :touch, "file[#{BREW_STAMP}]", :immediately
          end
        end
      end

      action :periodic, description: "Run a periodic update based on the frequency property." do
        return unless macos?

        unless brew_up_to_date?
          converge_by "update new lists of packages" do
            do_update
          end
        end
      end

      action :update, description: "Run an immediate update." do
        return unless macos?

        converge_by "force update new lists of packages" do
          do_update
        end
      end
    end
  end
end
