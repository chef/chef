#
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

class Chef
  class Provider
    class User
      class Aix < Chef::Provider::User::Useradd

        UNIVERSAL_OPTIONS = [[:comment, "-c"], [:gid, "-g"], [:shell, "-s"], [:uid, "-u"]]
        
        def create_user
          super
          add_password
        end

        def manage_user
          add_password
          super
        end

        # Aix does not support -r like other unix, sytem account is created by adding to 'system' group
        def useradd_options
          opts = []
          opts << "-g" << "system" if new_resource.system
          opts
        end

      private
        def add_password
          if @current_resource.password != @new_resource.password && @new_resource.password
            Chef::Log.debug("#{@new_resource.username} setting password to #{@new_resource.password}")
            command = "echo '#{@new_resource.username}:#{@new_resource.password}' | chpasswd -e"
            shell_out!(command)
          end
        end
      end
    end
  end
end
