#
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

describe Chef::Resource::WindowsWorkgroup do
  let(:resource) { Chef::Resource::WindowsWorkgroup.new("example") }
  let(:provider) { resource.provider_for_action(:join) }

  it "sets resource name as :windows_workgroup" do
    expect(resource.resource_name).to eql(:windows_workgroup)
  end

  it "the workgroup_name property is the name_property" do
    expect(resource.workgroup_name).to eql("example")
  end

  it "converts the legacy :immediate reboot property to :reboot_now" do
    resource.reboot(:immediate)
    expect(resource.reboot).to eql(:reboot_now)
  end

  it "converts the legacy :delayed reboot property to :request_reboot" do
    resource.reboot(:delayed)
    expect(resource.reboot).to eql(:request_reboot)
  end

  it "sets the default action as :join" do
    expect(resource.action).to eql([:join])
  end

  it "supports :join action" do
    expect { resource.action :join }.not_to raise_error
  end

  it "accepts :immediate, :reboot_now, :request_reboot, :delayed, or :never values for 'reboot' property" do
    expect { resource.reboot :immediate }.not_to raise_error
    expect { resource.reboot :delayed }.not_to raise_error
    expect { resource.reboot :reboot_now }.not_to raise_error
    expect { resource.reboot :request_reboot }.not_to raise_error
    expect { resource.reboot :never }.not_to raise_error
    expect { resource.reboot :nopenope }.to raise_error(ArgumentError)
  end

  describe "#join_command" do
    context "if password property is not specified" do
      it "constructs a command without credentials" do
        expect(provider.join_command).to eql("Add-Computer -WorkgroupName example -Force")
      end
    end

    context "if password property is specified" do
      it "constructs a command without credentials" do
        resource.password("1234")
        resource.user("admin")
        expect(provider.join_command).to eql("$pswd = ConvertTo-SecureString '1234' -AsPlainText -Force;$credential = New-Object System.Management.Automation.PSCredential (\"admin\",$pswd);Add-Computer -WorkgroupName example -Credential $credential -Force")
      end
    end
  end
end
