#
# Author:: Ashwini Nehate (<anehate@chef.io>)
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

describe Chef::Resource::WindowsSecurityPolicy, :windows_only do
  let(:secoption) { "MaximumPasswordAge" }
  let(:secvalue) { "30" }
  let(:windows_test_run_context) do
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
    new_resource = Chef::Resource::WindowsSecurityPolicy.new(secoption, windows_test_run_context)
    new_resource.secoption = secoption
    new_resource.secvalue = secvalue
    new_resource
  end

  describe "Set MaximumPasswordAge Policy" do
    after {
      subject.secvalue("60")
      subject.run_action(:set)
    }

    it "should set MaximumPasswordAge to 30" do
      subject.secvalue("30")
      subject.run_action(:set)
      expect(subject).to be_updated_by_last_action
    end

    it "should be idempotent" do
      subject.secvalue("30")
      subject.run_action(:set)
      guardscript_and_script_time = subject.elapsed_time
      subject.run_action(:set)
      only_guardscript_time = subject.elapsed_time
      expect(only_guardscript_time).to be < guardscript_and_script_time
    end
  end

  describe "secoption and id: " do
    it "accepts 'MinimumPasswordAge', 'MinimumPasswordAge', 'MaximumPasswordAge', 'MinimumPasswordLength', 'PasswordComplexity', 'PasswordHistorySize', 'LockoutBadCount', 'RequireLogonToChangePassword', 'ForceLogoffWhenHourExpire', 'NewAdministratorName', 'NewGuestName', 'ClearTextPassword', 'LSAAnonymousNameLookup', 'EnableAdminAccount', 'EnableGuestAccount' " do
      expect { subject.secoption("MinimumPasswordAge") }.not_to raise_error
      expect { subject.secoption("MaximumPasswordAge") }.not_to raise_error
      expect { subject.secoption("MinimumPasswordLength") }.not_to raise_error
      expect { subject.secoption("PasswordComplexity") }.not_to raise_error
      expect { subject.secoption("PasswordHistorySize") }.not_to raise_error
      expect { subject.secoption("LockoutBadCount") }.not_to raise_error
      expect { subject.secoption("RequireLogonToChangePassword") }.not_to raise_error
      expect { subject.secoption("ForceLogoffWhenHourExpire") }.not_to raise_error
      expect { subject.secoption("NewAdministratorName") }.not_to raise_error
      expect { subject.secoption("NewGuestName") }.not_to raise_error
      expect { subject.secoption("ClearTextPassword") }.not_to raise_error
      expect { subject.secoption("LSAAnonymousNameLookup") }.not_to raise_error
      expect { subject.secoption("EnableAdminAccount") }.not_to raise_error
      expect { subject.secoption("EnableGuestAccount") }.not_to raise_error
    end

    it "rejects any other option" do
      expect { subject.secoption "XYZ" }.to raise_error(ArgumentError)
    end
  end
end
