#
# Author:: Jay Mundrawala <jdm@chef.io>
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

require 'chef'
require 'chef/util/powershell/ps_credential'

describe Chef::Util::Powershell::PSCredential do
  let (:username) { 'foo' }
  let (:password) { 'password' }

  context 'when username and password are provided' do
    let(:ps_credential) { Chef::Util::Powershell::PSCredential.new(username, password)}
    context 'when calling to_psobject' do
      it 'should create the script to create a PSCredential when calling' do
        allow(ps_credential).to receive(:encrypt).with(password).and_return('encrypted')
        expect(ps_credential.to_psobject).to eq(
        "New-Object System.Management.Automation.PSCredential("\
            "'#{username}',('encrypted' | ConvertTo-SecureString))")
      end
    end
  end
end
