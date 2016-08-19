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
#

require "chef/resource/user"

class Chef
  class Resource
    class User
      class LinuxUser < Chef::Resource::User
        resource_name :linux_user

        provides :linux_user
        provides :user, os: "linux"

        def initialize(name, run_context = nil)
          super
          @supports = {
            manage_home: true,
            non_unique: true,
          }
          @manage_home = true
        end

        def supports(args = {})
          Chef.log_deprecation "setting supports on the linux_user resource is deprecated"
          # setting is deliberately disabled
          super({})
        end

        def supports=(args)
          Chef.log_deprecation "setting supports on the linux_user resource is deprecated"
          # setting is deliberately disabled
          supports({})
        end
      end
    end
  end
end
