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
end

describe "Chef::ReservedNames::Win32::Version", :windows_only, :not_supported_on_win2k3 do
  before do

    wmi = WmiInstance::Wmi.new
    host = wmi.first_of('Win32_OperatingSystem')

    # Use WMI to determine current OS version.
    # On Win2k8R2 and later, we can dynamically obtain marketing
    # names for comparison from WMI so the test should not
    # need to be modified when new Windows releases arise.
    # For Win2k3 and Win2k8, we use static names in this test
    # based on the version number information from WMI. The names
    # from WMI contain extended characters such as registered
    # trademark on Win2k8 and Win2k3 that we're not using in our
    # library, so we have to set the expectation statically.
    if Chef::Platform::windows_server_2003?
      @current_os_version = 'Windows Server 2003 R2'
    elsif is_windows_server_2008?(host)
      @current_os_version = 'Windows Server 2008'
    else
      # The name from WMI is actually what we want in Win2k8R2+.
      # So this expectation sould continue to hold without modification
      # as new versions of Windows are released.
      @current_os_version = host['caption']
    end

    @version = Chef::ReservedNames::Win32::Version.new
  end

  def for_each_windows_version(&block)
    @version.methods.each do |method_name|
      if Chef::ReservedNames::Win32::Version::WIN_VERSIONS.keys.find { | key | method_name.to_s == Chef::ReservedNames::Win32::Version.send(:method_name_from_marketing_name,key) }
        yield method_name
      end
    end
  end

  context "Win32 version object" do
    it "should have have one method for each marketing version" do
      versions = 0
      for_each_windows_version { versions += 1 }
      versions.should > 0
      versions.should == Chef::ReservedNames::Win32::Version::WIN_VERSIONS.length
    end

    it "should only contain version methods with legal method names" do
      method_name_pattern = /[a-z]+([a-z]|[0-9]|_)*\?{0,1}/

      for_each_windows_version do |method_name|
        method_match = method_name_pattern.match(method_name.to_s)
        method_match.should_not be_nil
        method_name.to_s.should == method_match[0]
      end
    end

    it "should have exactly one method that returns true" do
      true_versions = 0
      for_each_windows_version do |method_name|
        true_versions += 1 if @version.send(method_name)
      end
      true_versions.should == 1
    end

    it "should successfully execute all version methods" do
      for_each_windows_version { |method_name| @version.send(method_name.to_sym) }
    end
  end

  context "Windows Operating System version" do
    it "should match the version from WMI" do
      @current_os_version.should include(@version.marketing_name)
    end
  end

  def is_windows_server_2008?(wmi_host)
    is_win2k8 = false

    os_version = wmi_host['version']

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
  end
end
