#
# Author:: Jay Mundrawala(<jdm@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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

require 'spec_helper'
if Chef::Platform.windows?
  require 'chef/win32/crypto'
end

describe 'Chef::ReservedNames::Win32::Crypto', :windows_only do
  describe '#encrypt' do
    before(:all) do
      ohai_reader = Ohai::System.new
      ohai_reader.all_plugins("platform")

      new_node = Chef::Node.new
      new_node.consume_external_attrs(ohai_reader.data,{})

      events = Chef::EventDispatch::Dispatcher.new

      @run_context = Chef::RunContext.new(new_node, {}, events)
    end

    let (:plaintext) { 'p@assword' }

    it 'can be decrypted by powershell' do
      encrypted = Chef::ReservedNames::Win32::Crypto.encrypt(plaintext)
      resource = Chef::Resource::WindowsScript::PowershellScript.new("Powershell resource functional test", @run_context)
      resource.code <<-EOF
$encrypted = '#{encrypted}' | ConvertTo-SecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($encrypted)
$plaintext = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
if ($plaintext -ne '#{plaintext}') {
  Write-Error 'Got: ' $plaintext
  exit 1
}
exit 0
      EOF
      resource.returns(0)
      resource.run_action(:run)
    end
  end
end
