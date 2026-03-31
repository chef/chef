#
# Author:: Jay Mundrawala(<jdm@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require "spec_helper"
require "chef/mixin/powershell_exec"
if ChefUtils.windows?
  require "chef/win32/crypto"
end

describe "Chef::ReservedNames::Win32::Crypto", :windows_only do
  include Chef::Mixin::PowershellExec

  describe "#encrypt" do
    let(:plaintext) { "p@assword" }

    # Use powershell_exec! (chef-powershell / pwsh) rather than spawning a
    # Windows PowerShell 5.1 subprocess.  On GHA Windows runners the
    # Microsoft.PowerShell.Security module cannot be loaded inside a PS5.1
    # child process launched with -NoProfile from a D:\ working directory.
    # PS7 (pwsh) does not have this DLL-loading restriction and exercises the
    # same DPAPI path on Windows, so the test remains functionally equivalent.
    it "can be decrypted by powershell" do
      encrypted = Chef::ReservedNames::Win32::Crypto.encrypt(plaintext)
      result = powershell_exec!(<<~EOF)
        $encrypted = '#{encrypted}' | ConvertTo-SecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($encrypted)
        [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
      EOF
      expect(result.result).to eq(plaintext)
    end
  end
end
