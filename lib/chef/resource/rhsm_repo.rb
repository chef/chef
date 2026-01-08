#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

class Chef
  class Resource
    class RhsmRepo < Chef::Resource

      provides(:rhsm_repo, target_mode: true) { true }
      target_mode support: :full

      description "Use the **rhsm_repo** resource to enable or disable Red Hat Subscription Manager repositories that are made available via attached subscriptions."
      introduced "14.0"
      examples <<~DOC
        **Enable an RHSM repository**

        ```ruby
        rhsm_repo 'rhel-7-server-extras-rpms'
        ```

        **Disable an RHSM repository**

        ```ruby
        rhsm_repo 'rhel-7-server-extras-rpms' do
          action :disable
        end
        ```
      DOC

      property :repo_name, String,
        description: "An optional property for specifying the repository name if it differs from the resource block's name.",
        name_property: true

      action :enable, description: "Enable a RHSM repository." do
        execute "Enable repository #{new_resource.repo_name}" do
          command "subscription-manager repos --enable=#{new_resource.repo_name}"
          default_env true
          action :run
          not_if { repo_enabled?(new_resource.repo_name) }
        end
      end

      action :disable, description: "Disable a RHSM repository." do
        execute "Enable repository #{new_resource.repo_name}" do
          command "subscription-manager repos --disable=#{new_resource.repo_name}"
          default_env true
          action :run
          only_if { repo_enabled?(new_resource.repo_name) }
        end
      end

      action_class do
        def repo_enabled?(repo)
          # FIXME: Add `env` support
          cmd = shell_out("subscription-manager repos --list-enabled", env: { LANG: "en_US" })
          repo == "*" || !cmd.stdout.match(/Repo ID:\s+#{repo}$/).nil?
        end
      end
    end
  end
end
