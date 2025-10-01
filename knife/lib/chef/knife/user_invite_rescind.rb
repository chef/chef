#
# Author:: Steven Danna (<steve@chef.io>)
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

require_relative "../knife"

class Chef
  class Knife
    class UserInviteRescind < Chef::Knife
      category "user"
      banner "knife user invite rescind [USERNAMES] (options)"

      option :all,
        short: "-a",
        long: "--all",
        description: "Rescind all invites!"

      def run
        if (name_args.length < 1) && ! config.key?(:all)
          show_usage
          ui.fatal("You must specify a username.")
          exit 1
        end

        # To rescind we need to send a DELETE to association_requests/INVITE_ID
        # For user friendliness we look up the invite ID based on username.
        @invites = {}
        usernames = name_args
        rest.get_rest("association_requests").each { |i| @invites[i["username"]] = i["id"] }
        if config[:all]
          ui.confirm("Are you sure you want to rescind all association requests")
          @invites.each do |u, i|
            rest.delete_rest("association_requests/#{i}")
          end
        else
          ui.confirm("Are you sure you want to rescind the association requests for: #{usernames.join(", ")}")
          usernames.each do |u|
            if @invites.key?(u)
              rest.delete_rest("association_requests/#{@invites[u]}")
            else
              ui.fatal("No association request for #{u}.")
              exit 1
            end
          end
        end
      end
    end
  end
end
