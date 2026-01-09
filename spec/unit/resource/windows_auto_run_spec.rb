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

describe Chef::Resource::WindowsAutorun do
  let(:resource) { Chef::Resource::WindowsAutorun.new("fakey_fakerton") }

  it "sets resource name as :windows_auto_run" do
    expect(resource.resource_name).to eql(:windows_auto_run)
  end

  it "the program_name property is the name_property" do
    expect(resource.program_name).to eql("fakey_fakerton")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create, :remove actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  it "supports :machine and :user in the root property" do
    expect { resource.root :user }.not_to raise_error
    expect { resource.root :machine }.not_to raise_error
    expect { resource.root "user" }.to raise_error(ArgumentError)
  end

  it "coerces forward slashes to backslashes for the path" do
    resource.path "C:/something.exe"
    expect(resource.path).to eql("C:\\something.exe")
  end
end
