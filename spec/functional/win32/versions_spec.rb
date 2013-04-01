#
# Author:: Chirag Jog (<chirag@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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
  require 'chef/win32/version'
  require 'ruby-wmi'
end

describe "Chef::ReservedNames::Win32::Version", :windows_only do
  before do
    host = WMI::Win32_OperatingSystem.find(:first)
    @current_os_version = host.caption
    @version = Chef::ReservedNames::Win32::Version.new
  end
  context "Windows Operating System version" do
    it "should match the version from WMI" do
      @current_os_version.include?(@version.marketing_name).should == true
    end
  end
end
