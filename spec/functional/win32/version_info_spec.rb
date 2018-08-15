#
# Author:: Matt Wrock (<matt@mattwrock.com>)
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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
if Chef::Platform.windows?
  require "chef/win32/file/version_info"
end

describe "Chef::ReservedNames::Win32::File::VersionInfo", :windows_only do
  require "wmi-lite/wmi"
  let(:file_path) { ENV["ComSpec"] }
  let(:os_version) do
    wmi = WmiLite::Wmi.new
    os_info = wmi.first_of("Win32_OperatingSystem")
    os_info["version"]
  end

  subject { Chef::ReservedNames::Win32::File::VersionInfo.new(file_path) }

  it "file version has the same version as windows" do
    expect(subject.FileVersion).to start_with(os_version)
  end

  it "product version has the same version as windows" do
    expect(subject.ProductVersion).to start_with(os_version)
  end

  it "company is microsoft" do
    expect(subject.CompanyName).to eq("Microsoft Corporation")
  end

  it "file description is command processor" do
    expect(subject.FileDescription).to eq("Windows Command Processor")
  end
end
