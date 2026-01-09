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

describe Chef::Resource::WindowsUserPrivilege do
  let(:resource) { Chef::Resource::WindowsUserPrivilege.new("fakey_fakerton") }

  it "sets resource name as :windows_user_privilege" do
    expect(resource.resource_name).to eql(:windows_user_privilege)
  end

  it "the principal property is the name_property" do
    expect(resource.principal).to eql("fakey_fakerton")
  end

  it "the users property coerces to an array" do
    resource.users "Administrator"
    expect(resource.users).to eql(["Administrator"])
  end

  it "the privilege property coerces to an array" do
    resource.privilege "SeDenyRemoteInteractiveLogonRight"
    expect(resource.privilege).to eql(["SeDenyRemoteInteractiveLogonRight"])
  end

  it "the privilege property validates inputs against the allowed list of privs" do
    expect { resource.privilege "invalidPriv" }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "sets the default action as :add" do
    expect(resource.action).to eql([:add])
  end

  it "supports :add, :set, :clear, :remove actions" do
    expect { resource.action :add }.not_to raise_error
    expect { resource.action :set }.not_to raise_error
    expect { resource.action :clear }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end
end
