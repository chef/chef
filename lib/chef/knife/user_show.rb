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
    class UserShow < Knife

      include Knife::Core::MultiAttributeReturnOption

      banner "knife user show USER (options)"

      option :with_orgs,
        long: "--with-orgs",
        short: "-l"

      def run
        @user_name = @name_args[0]

        if @user_name.nil?
          show_usage
          ui.fatal("You must specify a user name")
          exit 1
        end

        results = root_rest.get("users/#{@user_name}")
        if config[:with_orgs]
          orgs = root_rest.get("users/#{@user_name}/organizations")
          results["organizations"] = orgs.map { |o| o["organization"]["name"] }
        end
        output(format_for_display(results))
      end

    end
  end
end
