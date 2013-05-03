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

    @version = Chef::ReservedNames::Win32::Version.new

    is_win2k8 = false
  
    os_version = host.send('Version')

    # The operating system version is a string in the following form
    # that can be split into components based on the '.' delimiter:
    # MajorVersionNumber.MinorVersionNumber.BuildNumber
    os_version_components = os_version.split('.')

    if os_version_components.length < 2
      raise 'WMI returned a Windows version from Win32_OperatingSystem.Version ' +
        'with an unexpected format. The Windows version could not be determined.'
    end

    # Windows 6.0 is Windows Server 2008, so test the major and
    # minor version components
    is_win2k8 = os_version_components[0] == '6' && os_version_components[1] == '0'

    # Ensure that the OS name returned by WMI does not have extended
    # characters like the registered trademark that get mapped to
    # the character 'r' -- this is an issue for Win2k8 only.
    # This gets normalized below
    if ! is_win2k8
      @current_os_version_canonicalized = host.caption
    else
      @current_os_version_canonicalized = 'Windows Server 2008'
    end

    `gem contents 'mixlib-shellout'`
  end

  context "Windows Operating System version" do
    it "should match the version from WMI", :not_supported_on_win2k3 do
      puts "WMI: #{@current_os_version_canonicalized} Resource: #{@version.marketing_name}"
      @current_os_version_canonicalized.include?(@version.marketing_name).should == true
    end

    context "Windows Server 2003", :windows_win2k3 do
      it "should report 'Windows Server 2003'" do
        @version.marketing_name.include?('Windows Server 2003') == true
      end            
    end
    
    
  end
end
