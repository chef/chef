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

class Chef
  class Knife
    class UserDelete < Knife

      deps do
        require "chef/user_v1"
        require "chef/json_compat"
      end

      banner "knife user delete USER (options)"

      def osc_11_warning
        <<-EOF
The Chef Server you are using does not support the username field.
This means it is an Open Source 11 Server.
knife user delete for Open Source 11 Server is being deprecated.
Open Source 11 Server user commands now live under the knife osc_user namespace.
For backwards compatibility, we will forward this request to knife osc_user delete.
If you are using an Open Source 11 Server, please use that command to avoid this warning.
EOF
      end

      def run_osc_11_user_delete
        # run osc_user_delete with our input
        ARGV.delete("user")
        ARGV.unshift("osc_user")
        Chef::Knife.run(ARGV, Chef::Application::Knife.options)
      end

      # DEPRECATION NOTE
      # Delete this override method after OSC 11 support is dropped
      def delete_object(user_name)
        confirm("Do you really want to delete #{user_name}")

        if Kernel.block_given?
          object = block.call
        else
          object = Chef::UserV1.load(user_name)
          object.destroy
        end

        output(format_for_display(object)) if config[:print_after]
        msg("Deleted #{user_name}")
      end

      def run
        @user_name = @name_args[0]

        if @user_name.nil?
          show_usage
          ui.fatal("You must specify a user name")
          exit 1
        end

        # DEPRECATION NOTE
        #
        # Below is modification of Chef::Knife.delete_object to detect OSC 11 server.
        # When OSC 11 is deprecated, simply delete all this and go back to:
        #
        # delete_object(Chef::UserV1, @user_name)
        #
        # Also delete our override of delete_object above
        object = Chef::UserV1.load(@user_name)

        # OSC 11 case
        if object.username.nil?
          ui.warn(osc_11_warning)
          run_osc_11_user_delete
        else # proceed with EC / CS delete
          delete_object(@user_name)
        end
      end
    end
  end
end
