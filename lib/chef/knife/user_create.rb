#
# Author:: Steven Danna (<steve@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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

require 'chef/knife'

class Chef
  class Knife
    class UserCreate < Knife

      attr_accessor :user_field

      deps do
        require 'chef/user'
        require 'chef/json_compat'
      end

      option :file,
        :short => "-f FILE",
        :long  => "--file FILE",
        :description => "Write the private key to a file, if returned by the server. A private key will be returned when both --user-key and --no-key are NOT passed. In that case, the server will generate a default key for you and return the private key it creates."

      option :admin,
        :short => "-a",
        :long  => "--admin",
        :description => "Create the user as an admin (only relevant for Open Source Chef Server 11).",
        :boolean => true

      option :user_key,
        :long => "--user-key FILENAME",
        :description => "Public key for newly created user. Path to a public key you provide instead of having the server generate one. If --user-key is not passed, the server will create a 'default' key for you, unless you passed --no-key. Note that --user-key cannot be passed with --no-key."

      option :no_key,
        :long => "--no-key",
        :description => "Do not create a 'default' public key for this new user. This prevents the server generating a public key by default. Cannot be passed with --user-key (requires server API version 1)."

      banner "knife user create USERNAME DISPLAY_NAME FIRST_NAME LAST_NAME EMAIL PASSWORD (options)"

      def user
        @user_field ||= Chef::User.new
      end

      def create_user_from_hash(hash)
        Chef::User.from_hash(hash).create
      end

      def run
        test_mandatory_field(@name_args[0], "username")
        user.username @name_args[0]

        test_mandatory_field(@name_args[1], "display name")
        user.display_name @name_args[1]

        test_mandatory_field(@name_args[2], "first name")
        user.first_name @name_args[2]

        test_mandatory_field(@name_args[3], "last name")
        user.last_name @name_args[3]

        test_mandatory_field(@name_args[4], "email")
        user.email @name_args[4]

        test_mandatory_field(@name_args[5], "password")
        user.password @name_args[5]

        if config[:user_key] && config[:no_key]
          show_usage
          ui.fatal("You cannot pass --user-key and --no-key")
          exit 1
        end

        user.admin(config[:admin])

        unless config[:no_key]
          user.create_key(true)
        end

        if config[:user_key]
          user.public_key File.read(File.expand_path(config[:user_key]))
        end

        output = edit_data(user)
        final_user = create_user_from_hash(output)

        ui.info("Created #{user}")
        if final_user.private_key
          if config[:file]
            File.open(config[:file], "w") do |f|
              f.print(final_user.private_key)
            end
          else
            ui.msg final_user.private_key
          end
        end
      end
    end
  end
end
