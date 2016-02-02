#
# Author:: Steven Danna (<steve@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

# DEPRECATION NOTE
# This code only remains to support users still operating with
# Open Source Chef Server 11 and should be removed once support
# for OSC 11 ends. New development should occur in user_reregister.rb.

class Chef
  class Knife
    class OscUserReregister < Knife

      deps do
        require "chef/user"
        require "chef/json_compat"
      end

      banner "knife osc_user reregister USER (options)"

      option :file,
        :short => "-f FILE",
        :long  => "--file FILE",
        :description => "Write the private key to a file"

      def run
        @user_name = @name_args[0]

        if @user_name.nil?
          show_usage
          ui.fatal("You must specify a user name")
          exit 1
        end

        user = Chef::User.load(@user_name).reregister
        Chef::Log.debug("Updated user data: #{user.inspect}")
        key = user.private_key
        if config[:file]
          File.open(config[:file], "w") do |f|
            f.print(key)
          end
        else
          ui.msg key
        end
      end
    end
  end
end
