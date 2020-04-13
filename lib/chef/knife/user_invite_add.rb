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
    class UserInviteAdd < Chef::Knife
      category "user"
      banner "knife user invite add USERNAMES"

      def run
        if name_args.length < 1
          show_usage
          ui.fatal("You must specify a username.")
          exit 1
        end

        users = name_args
        api_endpoint = "association_requests/"
        users.each do |u|
          body = { user: u }
          rest.post_rest(api_endpoint, body)
        end
      end
    end
  end
end
