#
# Author:: Tyler Cloke (<tyler@getchef.com>)
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
    class UserPassword < Knife
      banner "knife user password USERNAME [PASSWORD | --enable-external-auth]"

      option :enable_external_auth,
        long: "--enable-external-auth",
        short: "-e",
        description: "Enable external authentication for this user (such as LDAP)"

      def run
        # check that correct number of args was passed, should be either
        # USERNAME PASSWORD or USERNAME --enable-external-auth
        #
        # note that you can't pass USERNAME PASSWORD --enable-external-auth
        unless (@name_args.length == 2 && !config[:enable_external_auth]) || (@name_args.length == 1 && config[:enable_external_auth])
          show_usage
          ui.fatal("You must pass two arguments")
          ui.fatal("Note that --enable-external-auth cannot be passed with a password")
          exit 1
        end

        user_name = @name_args[0]

        # note that this will be nil if config[:enable_external_auth] is true
        password = @name_args[1]

        # since the API does not pass back whether recovery_authentication_enabled is
        # true or false, there is no way of knowing if the user is using ldap or not,
        # so we will update the user every time, instead of checking if we are actually
        # changing anything before we PUT.
        result = root_rest.get("users/#{user_name}")

        result["password"] = password unless password.nil?

        # if --enable-external-auth was passed, enable it, else disable it.
        # there is never a situation where we would want to enable ldap
        # AND change the password. changing the password means that the user
        # wants to disable ldap and put user in recover (if they are using ldap).
        result["recovery_authentication_enabled"] = !config[:enable_external_auth]

        begin
          root_rest.put("users/#{user_name}", result)
        rescue => e
          raise e
        end

        ui.msg("Authentication info updated for #{user_name}.")
      end
    end
  end
end
