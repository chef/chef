#
# Author:: Jay Mundrawala (<jdm@chef.io>)
#
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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

require 'chef/win32/crypto' if Chef::Platform.windows?

class Chef::Util::Powershell
  class PSCredential
    def initialize(username, password)
      @username = username
      @password = password
    end

    def to_psobject
      "New-Object System.Management.Automation.PSCredential('#{@username}',('#{encrypt(@password)}' | ConvertTo-SecureString))"
    end

    private

    def encrypt(str)
      Chef::ReservedNames::Win32::Crypto.encrypt(str)
    end
  end
end
