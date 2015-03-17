#
# Author:: Dave Eddy (<dave@daveeddy.com>)
# Copyright:: Copyright 2015, Dave Eddy
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'chef/mixin/shell_out'
require 'chef/provider/user/useradd'

class Chef
  class Provider
    class User
      class SmartOS < Chef::Provider::User::Useradd
        provides :user, os: 'solaris2', platform_family: 'smartos'

        def check_lock
          shadow_line = shell_out!('getent', 'shadow', new_resource.username).stdout.strip
          fields = shadow_line.split(':')

          # '*LK*...' and 'LK' are both considered locked,
          # so look for LK at the beginning of the shadow entry
          # optionally surrounded by '*'
          @locked = !!fields[1].match(/^\*?LK\*?/)

          @locked
        end

        def lock_user
          shell_out!('passwd', '-l', new_resource.username)
        end

        def unlock_user
          shell_out!('passwd', '-u', new_resource.username)
        end
      end
    end
  end
end
