#
# Author:: Marc Paradise (<marc@chef.io>)
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

class Chef
  class Knife
    class OrgUserAdd < Knife
      category "CHEF ORGANIZATION MANAGEMENT"
      banner "knife org user add ORG_NAME USER_NAME"
      attr_accessor :org_name, :username

      option :admin,
        long: "--admin",
        short: "-a",
        description: "Add user to admin group"

      deps do
        require "chef/org"
      end

      def run
        @org_name, @username = @name_args

        if !org_name || !username
          ui.fatal "You must specify an ORG_NAME and USER_NAME"
          show_usage
          exit 1
        end

        org = Chef::Org.new(@org_name)
        begin
          org.associate_user(@username)
        rescue Net::HTTPServerException => e
          if e.response.code == "409"
            ui.msg "User #{username} already associated with organization #{org_name}"
          else
            raise e
          end
        end
        if config[:admin]
          org.add_user_to_group("admins", @username)
          org.add_user_to_group("billing-admins", @username)
          ui.msg "User #{username} is added to admins and billing-admins group"
        end
      end
    end
  end
end
