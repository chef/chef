#
# Author:: Serdar Sutay (<serdar@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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
  require 'chef/win32/security'
end

describe 'Chef::Win32::Security', :windows_only do
  it "has_admin_privileges? returns true when running as admin" do
    Chef::ReservedNames::Win32::Security.has_admin_privileges?.should == true
  end

  # We've done some investigation adding a negative test and it turned
  # out to be a lot of work since mixlib-shellout doesn't have user
  # support for windows.
  #
  # TODO - Add negative tests once mixlib-shellout has user support
  it "has_admin_privileges? returns false when running as non-admin" do
    pending "requires user support in mixlib-shellout"
  end
end
