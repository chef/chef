#
# Author:: Jay Mundrawala (<jdm@chef.io>)
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "../../win32/crypto" if ChefUtils.windows?

class Chef
  class Util
    class Powershell
      class PSCredential
        def initialize(username, password)
          @username = username
          @password = password
        end

        def to_psobject
          "New-Object System.Management.Automation.PSCredential('#{@username}',('#{encrypt(@password)}' | ConvertTo-SecureString))"
        end

        def to_plaintext
          "#<Chef::Util::Powershell::PSCredential:#{object_id} @username=#{@username.inspect}>"
        end

        # These leak an encrypted password, however we can't rely on no-one using
        # these assuming that behavior.
        alias to_s to_psobject
        alias to_text to_psobject

        # Inspect has no business leaking anything but the username, and to be honest
        # even that one could be dicey
        alias inspect to_plaintext

        private

        def encrypt(str)
          Chef::ReservedNames::Win32::Crypto.encrypt(str)
        end
      end
    end
  end
end
