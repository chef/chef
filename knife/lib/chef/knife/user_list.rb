#
# Author:: Steven Danna (<steve@chef.io>)
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

require_relative "../knife"

class Chef
  class Knife
    class UserList < Knife

      deps do
        # is not used there, only in knife.
        require "chef/user_v1" unless defined?(Chef::UserV1)
      end

      banner "knife user list (options)"

      option :with_uri,
             short: "-w",
             long: "--with-uri",
             description: "Show corresponding URIs."

      option :all_users,
             short: "-a",
             long: "--all-users",
             description: "Show all user details."

      def run
        users = Chef::UserV1.list(config[:all_users])
        if config[:all_users]
          # When showing all user details, convert UserV1 objects to hashes for display
          detailed_users = {}
          users.each do |name, user|
            detailed_users[name] = user.to_h
          end
          output(detailed_users)
        else
          output(format_list_for_display(users))
        end
      end

    end
  end
end
