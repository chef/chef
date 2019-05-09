#
# Copyright:: Copyright 2016-2017, Chef Software Inc.
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

require_relative "../user"

class Chef
  class Resource
    class User
      class DsclUser < Chef::Resource::User
        resource_name :dscl_user

        provides :dscl_user
        provides :user, os: "darwin"

        property :iterations, Integer,
                  description: "macOS platform only. The number of iterations for a password with a SALTED-SHA512-PBKDF2 shadow hash.",
                  default: 27855, desired_state: false
      end
    end
  end
end
