# Author: John McCrae (john.mccrae@progress.com)
# Copyright:: Copyright (c) Chef Software Inc.
# License: Apache License, Version 2.0
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
require "chef/resource/hostname"

describe Chef::Resource::Hostname, :windows_only do
  include Chef::Mixin::PowershellExec

  def get_domain_status
    powershell_exec!("(Get-WmiObject -Class Win32_ComputerSystem).PartofDomain").result
  end

  let(:new_hostname) { "New-Hostname" }
  let(:local_domain_user) { "'mydomain\\Groucho'" }
  let(:local_domain_password) { "'P@ssw0rd'" }
  let(:local_windows_reboot) { false }
  let(:domain_status) { get_domain_status }

  let(:run_context) do
    node = Chef::Node.new
    node.consume_external_attrs(OHAI_SYSTEM.data, {}) # node[:languages][:powershell][:version]
    node.automatic["os"] = "windows"
    node.automatic["platform"] = "windows"
    node.automatic["platform_version"] = "6.1"
    node.automatic["kernel"][:machine] = :x86_64 # Only 64-bit architecture is supported
    empty_events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, {}, empty_events)
  end

  subject do
    new_resource = Chef::Resource::Hostname.new("oldhostname", run_context)
    new_resource.hostname = "Grendel"
    new_resource.windows_reboot = false
    new_resource
  end

  describe "Changing machine names" do
    context "The system can be renamed without a user or password when in a Workgroup" do
      let(:hostname) { "Cucumber" }
      it "does change" do
        subject.run_action(:set)
        expect(subject).to be_updated_by_last_action
      end
    end

    describe "Mocking being joined to a domain" do
      before do
        allow(subject).to receive(:is_domain_joined?) { true }
      end
      context "the system gets renamed when in a domain" do
        let(:hostname) { "Gherkin" }
        it "does change the domain account" do
          subject.windows_reboot true
          subject.domain_user local_domain_user
          subject.domain_password local_domain_password
          subject.run_action(:set)
          expect(subject).to be_updated_by_last_action
        end
      end
    end

    describe "testing for error handling" do
      before do
        allow(subject).to receive(:is_domain_joined?) { true }
      end
      context "when a node is renamed while in a domain" do
        it "and fails because of missing credentials" do
          subject.windows_reboot true
          subject.domain_user local_domain_user
          expect { subject.run_action(:set) }.to raise_error(RuntimeError)
        end
      end
    end
  end
end
