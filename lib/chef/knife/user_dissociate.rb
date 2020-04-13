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
    class UserDissociate < Chef::Knife
      category "user"
      banner "knife user dissociate USERNAMES"

      def run
        if name_args.length < 1
          show_usage
          ui.fatal("You must specify a username.")
          exit 1
        end
        users = name_args
        ui.confirm("Are you sure you want to dissociate the following users: #{users.join(", ")}")
        users.each do |u|
          api_endpoint = "users/#{u}"
          rest.delete_rest(api_endpoint)
        end
      end
    end
  end
end
