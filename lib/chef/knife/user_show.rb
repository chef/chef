#
# Author:: Steven Danna (<steve@chef.io>)
# Copyright:: Copyright 2009-2016, Chef Software Inc.
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

class Chef
  class Knife
    class UserShow < Knife

      include Knife::Core::MultiAttributeReturnOption

      deps do
        require "chef/user_v1"
        require "chef/json_compat"
      end

      banner "knife user show USER (options)"

      def osc_11_warning
        <<-EOF
The Chef Server you are using does not support the username field.
This means it is an Open Source 11 Server.
knife user show for Open Source 11 Server is being deprecated.
Open Source 11 Server user commands now live under the knife osc_user namespace.
For backwards compatibility, we will forward this request to knife osc_user show.
If you are using an Open Source 11 Server, please use that command to avoid this warning.
EOF
      end

      def run_osc_11_user_show
        # run osc_user_edit with our input
        ARGV.delete("user")
        ARGV.unshift("osc_user")
        Chef::Knife.run(ARGV, Chef::Application::Knife.options)
      end

      def run
        @user_name = @name_args[0]

        if @user_name.nil?
          show_usage
          ui.fatal("You must specify a user name")
          exit 1
        end

        user = Chef::UserV1.load(@user_name)

        # DEPRECATION NOTE
        # Remove this if statement and corrosponding code post OSC 11 support.
        #
        # if username is nil, we are in the OSC 11 case,
        # forward to deprecated command
        if user.username.nil?
          ui.warn(osc_11_warning)
          run_osc_11_user_show
        else
          output(format_for_display(user))
        end
      end

    end
  end
end
