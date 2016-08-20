#
# Copyright:: Copyright 2016, Chef Software Inc.
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

require "chef/provider/user/useradd"

class Chef
  class Provider
    class User
      class Linux < Chef::Provider::User::Useradd
        # MAJOR XXX: the implementation of "linux" is the base class and all needs to be moved here
        provides :linux_user
        provides :user, os: "linux"

        def managing_home_dir?
          new_resource.manage_home # linux always 'supports' manage_home
        end
      end
    end
  end
end
