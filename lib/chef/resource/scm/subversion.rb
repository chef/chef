#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Author:: Tyler Cloke (<tyler@chef.io>)
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

require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class Subversion < Chef::Resource
      use "scm"

      provides :subversion, target_mode: true
      target_mode support: :full

      description "Use the **subversion** resource to manage source control resources that exist in a Subversion repository. Warning: The subversion resource has known bugs and may not work as expected. For more information see Chef GitHub issues, particularly [#4050](https://github.com/chef/chef/issues/4050) and [#4257](https://github.com/chef/chef/issues/4257)."
      examples <<~DOC
      **Get the latest version of an application**

      ```ruby
      subversion 'CouchDB Edge' do
        repository 'http://svn.apache.org/repos/asf/couchdb/trunk'
        revision 'HEAD'
        destination '/opt/my_sources/couch'
        action :sync
      end
      ```
      DOC

      allowed_actions :force_export

      property :svn_arguments, [String, nil, FalseClass],
        description: "The extra arguments that are passed to the Subversion command.",
        coerce: proc { |v| v == false ? nil : v }, # coerce false to nil
        default: "--no-auth-cache"

      property :svn_info_args, [String, nil, FalseClass],
        description: "Use when the `svn info` command is used by #{ChefUtils::Dist::Infra::PRODUCT} and arguments need to be passed. The `svn_arguments` command does not work when the `svn info` command is used.",
        coerce: proc { |v| v == false ? nil : v }, # coerce false to nil
        default: "--no-auth-cache"

      property :svn_binary, String,
        description: "The location of the svn binary."

      property :svn_username, String,
        description: "The user name for a user that has access to the Subversion repository."

      property :svn_password, String,
        description: "The password for a user that has access to the Subversion repository.",
        sensitive: true, desired_state: false

      # Override exception to strip password if any, so it won't appear in logs and different Chef notifications
      def custom_exception_message(e)
        "#{self} (#{defined_at}) had an error: #{e.class.name}: #{svn_password ? e.message.gsub(svn_password, "[hidden_password]") : e.message}"
      end
    end
  end
end
