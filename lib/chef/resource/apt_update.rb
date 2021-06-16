#
# Author:: Thom May (<thom@chef.io>)
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

require_relative "../resource"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class AptUpdate < Chef::Resource
      unified_mode true

      provides(:apt_update) { true }

      description "Use the **apt_update** resource to manage APT repository updates on Debian and Ubuntu platforms."
      introduced "12.7"
      examples <<~DOC
        **Update the Apt repository at a specified interval**:

        ```ruby
        apt_update 'all platforms' do
          frequency 86400
          action :periodic
        end
        ```

        **Update the Apt repository at the start of a Chef Infra Client run**:

        ```ruby
        apt_update 'update'
        ```
      DOC

      # allow bare apt_update with no name
      property :name, String, default: ""

      property :frequency, Integer,
        description: "Determines how frequently (in seconds) APT repository updates are made. Use this property when the `:periodic` action is specified.",
        default: 86_400

      default_action :periodic
      allowed_actions :update, :periodic

      action_class do
        APT_CONF_DIR = "/etc/apt/apt.conf.d".freeze
        STAMP_DIR = "/var/lib/apt/periodic".freeze

        # Determines whether we need to run `apt-get update`
        #
        # @return [Boolean]
        def apt_up_to_date?
          ::File.exist?("#{STAMP_DIR}/update-success-stamp") &&
            ::File.mtime("#{STAMP_DIR}/update-success-stamp") > Time.now - new_resource.frequency
        end

        def do_update
          [STAMP_DIR, APT_CONF_DIR].each do |d|
            directory d do
              recursive true
            end
          end

          file "#{APT_CONF_DIR}/15update-stamp" do
            content "APT::Update::Post-Invoke-Success {\"touch #{STAMP_DIR}/update-success-stamp 2>/dev/null || true\";};\n"
            action :create_if_missing
          end

          execute "apt-get -q update" do
            command [ "apt-get", "-q", "update" ]
            default_env true
          end
        end
      end

      action :periodic, description: "Update the Apt repository at the interval specified by the `frequency` property." do
        return unless debian?

        unless apt_up_to_date?
          converge_by "update new lists of packages" do
            do_update
          end
        end
      end

      action :update, description: "Update the Apt repository at the start of a #{ChefUtils::Dist::Infra::PRODUCT} run." do
        return unless debian?

        converge_by "force update new lists of packages" do
          do_update
        end
      end

    end
  end
end
