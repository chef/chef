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
      class Illumos < Chef::Provider::User::Solaris

        def lock_user
          shell_out!("passwd -l #{@new_resource.username}")
        end

        def unlock_user
          shell_out!("passwd -u #{@new_resource.username}")
        end

        private

        def check_lock_status
          shell_out("passwd -s #{@new_resource.username}")
        end
      end
    end
  end
end
