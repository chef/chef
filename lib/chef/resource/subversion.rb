#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require_relative "scm"
require_relative "../dist"

class Chef
  class Resource
    class Subversion < Chef::Resource::Scm
      description "Use the subversion resource to manage source control resources that exist in a Subversion repository."

      allowed_actions :force_export

      property :svn_arguments, [String, nil, FalseClass],
               description: "The extra arguments that are passed to the Subversion command.",
               coerce: proc { |v| v == false ? nil : v }, # coerce false to nil
               default: "--no-auth-cache"

      property :svn_info_args, [String, nil, FalseClass],
               description: "Use when the svn info command is used by the #{Chef::Dist::CLIENT} and arguments need to be passed. The svn_arguments command does not work when the svn info command is used.",
               coerce: proc { |v| v == false ? nil : v }, # coerce false to nil
               default: "--no-auth-cache"

      property :svn_binary, String,
               description: "The location of the svn binary."

      property :svn_username, String,
               description: "The username to use for interacting with subversion."

      property :svn_password, String,
               description: "The password to use for interacting with subversion.",
               sensitive: true, desired_state: false

      # Override exception to strip password if any, so it won't appear in logs and different Chef notifications
      def custom_exception_message(e)
        "#{self} (#{defined_at}) had an error: #{e.class.name}: #{svn_password ? e.message.gsub(svn_password, "[hidden_password]") : e.message}"
      end
    end
  end
end
