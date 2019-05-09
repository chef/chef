#
# Author:: Steven Danna (<steve@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software, Inc.
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
require_relative "../dist"

class Chef
  class Knife
    class UserCreate < Knife

      attr_accessor :user_field

      deps do
        require_relative "../user_v1"
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
        description: "API V1 (#{Chef::Dist::SERVER_PRODUCT} 12.1+) only. Prevent server from generating a default key pair for you. Cannot be passed with --user-key.",
        boolean: true

      banner "knife user create USERNAME DISPLAY_NAME FIRST_NAME LAST_NAME EMAIL PASSWORD (options)"

      def user
        @user_field ||= Chef::UserV1.new
      end

      def create_user_from_hash(hash)
        Chef::UserV1.from_hash(hash).create
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

        output = edit_hash(user)
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
