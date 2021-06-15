#
# Copyright:: Copyright (c) Chef Software Inc.
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

describe Chef::Resource::WindowsDefender do
  let(:resource) { Chef::Resource::WindowsDefender.new("fakey_fakerton") }

  it "sets resource name as :windows_defender" do
    expect(resource.resource_name).to eql(:windows_defender)
  end

  it "sets the default action as :enable" do
    expect(resource.action).to eql([:enable])
  end

  it "supports :enable, :disable actions" do
    expect { resource.action :enable }.not_to raise_error
    expect { resource.action :disable }.not_to raise_error
  end

  it "realtime_protection property defaults to true" do
    expect(resource.realtime_protection).to eql(true)
  end

  it "intrusion_protection_system property defaults to true" do
    expect(resource.intrusion_protection_system).to eql(true)
  end

  it "lock_ui property defaults to true" do
    expect(resource.lock_ui).to eql(false)
  end

  it "scan_archives property defaults to true" do
    expect(resource.scan_archives).to eql(true)
  end

  it "scan_scripts property defaults to true" do
    expect(resource.scan_scripts).to eql(false)
  end

  it "scan_email property defaults to true" do
    expect(resource.scan_email).to eql(false)
  end

  it "scan_removable_drives property defaults to true" do
    expect(resource.scan_removable_drives).to eql(false)
  end

  it "scan_network_files property defaults to true" do
    expect(resource.scan_network_files).to eql(false)
  end

  it "scan_mapped_drives property defaults to true" do
    expect(resource.scan_mapped_drives).to eql(true)
  end
end
