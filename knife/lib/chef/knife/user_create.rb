#
# Author:: Tyler Cloke (<tyler@chef.io>)
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
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Knife
    class UserCreate < Knife

      attr_accessor :user_field

      deps do
        require "chef/user_v1" unless defined?(Chef::UserV1)
      end

      option :file,
        short: "-f FILE",
        long: "--file FILE",
        description: "Write the private key to a file if the server generated one."

      option :user_key,
        long: "--user-key FILENAME",
        description: "Set the initial default key for the user from a file on disk (cannot pass with --prevent-keygen)."

      option :prevent_keygen,
        short: "-k",
        long: "--prevent-keygen",
        description: "API V1 (#{ChefUtils::Dist::Server::PRODUCT} 12.1+) only. Prevent server from generating a default key pair for you. Cannot be passed with --user-key.",
        boolean: true

      option :orgname,
        long: "--orgname ORGNAME",
        short: "-o ORGNAME",
        description: "Associate new user to an organization matching ORGNAME"

      option :passwordprompt,
        long: "--prompt-for-password",
        short: "-p",
        description: "Prompt for user password"

      option :first_name,
        long: "--first-name FIRST_NAME",
        description: "First name for the user"

      option :last_name,
        long: "--last-name LAST_NAME",
        description: "Last name for the user"

      option :email,
        long: "--email EMAIL",
        description: "Email for the user"

      option :password,
        long: "--password PASSWORD",
        description: "Password for the user"

      banner "knife user create USERNAME --email EMAIL --password PASSWORD (options)"

      def user
        @user_field ||= Chef::UserV1.new
      end

      def run
        test_mandatory_field(@name_args[0], "username")
        user.username @name_args[0]

        if @name_args.size > 1
          ui.warn "[DEPRECATED] DISPLAY_NAME FIRST_NAME LAST_NAME EMAIL PASSWORD options are deprecated and will be removed in future release. Use USERNAME --email --password TAGS option instead."
          test_mandatory_field(@name_args[1], "display name")
          user.display_name @name_args[1]
          test_mandatory_field(@name_args[2], "first name")
          user.first_name @name_args[2]
          test_mandatory_field(@name_args[3], "last name")
          user.last_name @name_args[3]
          test_mandatory_field(@name_args[4], "email")
          user.email @name_args[4]
          password = config[:passwordprompt] ? prompt_for_password : @name_args[5]
        else
          test_mandatory_field(config[:email], "email")
          test_mandatory_field(config[:password], "password") unless config[:passwordprompt]
          user.display_name user.username
          user.first_name config[:first_name] || ""
          user.last_name config[:last_name] || ""
          user.email config[:email]
          password = config[:passwordprompt] ? prompt_for_password : config[:password]
        end

        unless password
          ui.fatal "You must either provide a password or use the --prompt-for-password (-p) option"
          exit 1
        end

        if config[:user_key] && config[:prevent_keygen]
          show_usage
          ui.fatal("You cannot pass --user-key and --prevent-keygen")
          exit 1
        end

        if !config[:prevent_keygen] && !config[:user_key]
          user.create_key(true)
        end

        if config[:user_key]
          user.public_key File.read(File.expand_path(config[:user_key]))
        end

        if @name_args.size > 1
          user_hash = {
            username: user.username,
            first_name: user.first_name,
            last_name: user.last_name,
            display_name: "#{user.first_name} #{user.last_name}",
            email: user.email,
            password: password,
          }
        else
          user_hash = {
            username: user.username,
            first_name: user.first_name,
            last_name: user.last_name,
            display_name: user.display_name,
            email: user.email,
            password: password,
          }
        end

        # Check the file before creating the user so the api is more transactional.
        if config[:file]
          file = config[:file]
          unless File.exist?(file) ? File.writable?(file) : File.writable?(File.dirname(file))
            ui.fatal "File #{config[:file]} is not writable.  Check permissions."
            exit 1
          end
        end

        final_user = root_rest.post("users/", user_hash)

        if config[:orgname]
          request_body = { user: user.username }
          response = root_rest.post("organizations/#{config[:orgname]}/association_requests", request_body)
          association_id = response["uri"].split("/").last
          root_rest.put("users/#{user.username}/association_requests/#{association_id}", { response: "accept" })
        end

        ui.info("Created #{user.username}")
        if final_user["private_key"]
          if config[:file]
            File.open(config[:file], "w") do |f|
              f.print(final_user["private_key"])
            end
          else
            ui.msg final_user["private_key"]
          end
        end
      end

      def prompt_for_password
        ui.ask("Please enter the user's password: ", echo: false)
      end
    end
  end
end
