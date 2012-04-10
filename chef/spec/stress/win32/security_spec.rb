#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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
require 'chef/win32/security'
require 'tmpdir'
require 'fileutils'

describe Chef::Win32::Security do

  Security = Chef::Win32::Security

  def monkeyfoo
    File.join(CHEF_SPEC_DATA, "monkeyfoo").gsub("/", "\\")
  end

  before :all do
    @test_tempdir = File.join(Dir::tmpdir, "cheftests", "chef_win32_security")
    FileUtils.mkdir_p(@test_tempdir)
    @monkeyfoo = File.join(@test_tempdir, "monkeyfoo.txt")
  end

  before :each do
    File.delete(@monkeyfoo) if File.exist?(@monkeyfoo)
    # Make a file.
    File.open(@monkeyfoo, "w") do |file|
      file.write("hi")
    end
  end

  after :all do
    FileUtils.rm_rf(@test_tempdir)
  end

  it "should not leak when retrieving and reading the ACE from a file" do
    lambda {
      sids = Security::SecurableObject.new(@monkeyfoo).security_descriptor.dacl.select { |ace| ace.sid }
      GC.start
    }.should_not leak_memory(:warmup => 50, :iterations => 100)
  end

  it "should not leak when creating a new ACL and setting it on a file" do
    securable_object = Security::SecurableObject.new(@monkeyfoo)
    lambda {
      securable_object.dacl = Security::ACL.create([
        Security::ACE.access_allowed(Security::SID.Everyone, Chef::Win32::API::Security::GENERIC_READ),
        Security::ACE.access_denied(Security::SID.from_account("Users"), Chef::Win32::API::Security::GENERIC_ALL)
      ])
      GC.start
    }.should_not leak_memory(:warmup => 50, :iterations => 100)
  end

end
