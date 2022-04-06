#
# Copyright:: Copyright (c) Chef Software Inc.
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
      class LinuxUser < Chef::Resource::User

        provides :linux_user
        provides :user, os: "linux"

        property :expire_date, [ String, NilClass ],
                 description: "(Linux) The date on which the user account will be disabled. The date is specified in the format YYYY-MM-DD.",
                 introduced: "17.8",
                 desired_state: false

        property :inactive, [ String, Integer, NilClass ],
                 description: "(Linux) The number of days after a password expires until the account is permanently disabled. A value of 0 disables the account as soon as the password has expired, and a value of -1 disables the feature.",
                 introduced: "17.8",
                 desired_state: false

      end
    end
  end
end
