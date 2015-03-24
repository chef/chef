#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

describe "Chef::Platform#windows_server_2003?" do
  it "returns false early when not on windows" do
    allow(Chef::Platform).to receive(:windows?).and_return(false)
    expect(Chef::Platform).not_to receive(:require) 
    expect(Chef::Platform.windows_server_2003?).to be_falsey
  end

  # CHEF-4888: Need to call WIN32OLE.ole_initialize in new threads
  it "does not raise an exception" do
    expect { Thread.fork { Chef::Platform.windows_server_2003? }.join }.not_to raise_error
  end
end

describe 'Chef::Platform#supports_dsc?' do 
  it 'returns false if powershell is not present' do
    node = Chef::Node.new
    expect(Chef::Platform.supports_dsc?(node)).to be_falsey
  end

  ['1.0', '2.0', '3.0'].each do |version|
    it "returns false for Powershell #{version}" do
      node = Chef::Node.new
      node.automatic[:languages][:powershell][:version] = version
      expect(Chef::Platform.supports_dsc?(node)).to be_falsey
    end
  end

  ['4.0', '5.0'].each do |version|
    it "returns true for Powershell #{version}" do
      node = Chef::Node.new
      node.automatic[:languages][:powershell][:version] = version
      expect(Chef::Platform.supports_dsc?(node)).to be_truthy
    end
  end
end

describe 'Chef::Platform#supports_dsc_invoke_resource?' do 
  it 'returns false if powershell is not present' do
    node = Chef::Node.new
    expect(Chef::Platform.supports_dsc_invoke_resource?(node)).to be_falsey
  end

  ['1.0', '2.0', '3.0', '4.0', '5.0.10017.9'].each do |version|
    it "returns false for Powershell #{version}" do
      node = Chef::Node.new
      node.automatic[:languages][:powershell][:version] = version
      expect(Chef::Platform.supports_dsc_invoke_resource?(node)).to be_falsey
    end
  end

  it "returns true for Powershell 5.0.10018.0" do
    node = Chef::Node.new
    node.automatic[:languages][:powershell][:version] = "5.0.10018.0"
    expect(Chef::Platform.supports_dsc_invoke_resource?(node)).to be_truthy
  end
end

