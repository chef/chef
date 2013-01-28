#
# Author:: Steven Danna (<steve@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

      deps do
        require 'chef/user'
        require 'chef/json_compat'
      end

      option :file,
        :short => "-f FILE",
        :long  => "--file FILE",
        :description => "Write the private key to a file"

      option :admin,
        :short => "-a",
        :long  => "--admin",
        :description => "Create the user as an admin",
        :boolean => true

      option :user_password,
        :short => "-p PASSWORD",
        :long => "--password PASSWORD",
        :description => "Password for newly created user",
        :default => ""

      option :user_key,
        :long => "--user-key FILENAME",
        :description => "Public key for newly created user.  By default a key will be created for you."

      banner "knife user create USER (options)"

      def run
        @user_name = @name_args[0]

        if @user_name.nil?
          show_usage
          ui.fatal("You must specify a user name")
          exit 1
        end

        if config[:user_password].length == 0
          show_usage
          ui.fatal("You must specify a non-blank password")
          exit 1
        end

        user = Chef::User.new
        user.name(@user_name)
        user.admin(config[:admin])
        user.password config[:user_password]

        if config[:user_key]
          user.public_key File.read(File.expand_path(config[:user_key]))
        end

        output = edit_data(user)
        user = Chef::User.from_hash(output).create

        ui.info("Created #{user}")
        if user.private_key
          if config[:file]
            File.open(config[:file], "w") do |f|
              f.print(user.private_key)
            end
          else
            puts user.private_key
          end
        end
      end
    end
  end
end
