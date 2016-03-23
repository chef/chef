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

require "chef/knife"
require "chef/knife/osc_user_create"

class Chef
  class Knife
    class UserCreate < Knife

      attr_accessor :user_field

      deps do
        require "chef/user_v1"
        require "chef/json_compat"
      end

      option :file,
        :short => "-f FILE",
        :long  => "--file FILE",
        :description => "Write the private key to a file if the server generated one."

      option :user_key,
        :long => "--user-key FILENAME",
        :description => "Set the initial default key for the user from a file on disk (cannot pass with --prevent-keygen)."

      option :prevent_keygen,
        :short => "-k",
        :long  => "--prevent-keygen",
        :description => "API V1 (Chef Server 12.1+) only. Prevent server from generating a default key pair for you. Cannot be passed with --user-key.",
        :boolean => true

      option :admin,
        :short => "-a",
        :long  => "--admin",
        :description => "DEPRECATED: Open Source Chef 11 only. Create the user as an admin.",
        :boolean => true

      option :user_password,
        :short => "-p PASSWORD",
        :long => "--password PASSWORD",
        :description => "DEPRECATED: Open Source Chef 11 only. Password for newly created user.",
        :default => ""

      banner "knife user create USERNAME DISPLAY_NAME FIRST_NAME LAST_NAME EMAIL PASSWORD (options)"

      def user
        @user_field ||= Chef::UserV1.new
      end

      def create_user_from_hash(hash)
        Chef::UserV1.from_hash(hash).create
      end

      def osc_11_warning
        <<-EOF
IF YOU ARE USING CHEF SERVER 12+, PLEASE FOLLOW THE INSTRUCTIONS UNDER knife user create --help.
You only passed a single argument to knife user create.
For backwards compatibility, when only a single argument is passed,
knife user create assumes you want Open Source 11 Server user creation.
knife user create for Open Source 11 Server is being deprecated.
Open Source 11 Server user commands now live under the knife osc_user namespace.
For backwards compatibility, we will forward this request to knife osc_user create.
If you are using an Open Source 11 Server, please use that command to avoid this warning.
EOF
      end

      def run_osc_11_user_create
        # run osc_user_create with our input
        ARGV.delete("user")
        ARGV.unshift("osc_user")
        Chef::Knife.run(ARGV, Chef::Application::Knife.options)
      end

      def run
        # DEPRECATION NOTE
        # Remove this if statement and corrosponding code post OSC 11 support.
        #
        # If only 1 arg is passed, assume OSC 11 case.
        if @name_args.length == 1
          ui.warn(osc_11_warning)
          run_osc_11_user_create
        else # EC / CS 12 user create

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
end
