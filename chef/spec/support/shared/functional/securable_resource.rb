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

shared_examples_for "a securable resource" do
  context "security" do
    describe "unix-specific behavior" do
      before(:each) do
        pending "SKIPPED - platform specific test" if windows?
        require 'etc'
        @expected_user_name = 'nobody'
        @expected_group_name = 'nobody'
        @expected_uid = Etc.getpwnam(@expected_user_name).uid
        @expected_gid = Etc.getgrnam(@expected_group_name).gid
      end

      it "should set an owner" do
        resource.owner @expected_user_name
        resource.run_action(:create)
        File.stat(path).uid.should == @expected_uid
      end

      it "should set a group" do
        resource.group @expected_group_name
        resource.run_action(:create)
        File.stat(path).gid.should == @expected_gid
      end

      it "should set permissions in string form as an octal number" do
        mode_string = '777'
        resource.mode mode_string
        resource.run_action(:create)
        (File.stat(path).mode & 007777).should == (mode_string.oct & 007777)
      end

      it "should set permissions in numeric form as a ruby-interpreted integer" do
        mode_integer = 0777
        resource.mode mode_integer
        resource.run_action(:create)
        (File.stat(path).mode & 007777).should == (mode_integer & 007777)
      end
    end

    describe "windows-specific behavior" do
      before(:each) do
        pending "SKIPPED - platform specific test" unless windows?
      end

      it "should set an owner" do
        pending "TODO WRITE THIS"
      end

      it "should set a group" do
        pending "TODO WRITE THIS"
      end

      it "should set permissions using the windows-only rights attribute" do
        pending "TODO WRITE THIS"
      end

      it "should set permissions in string form as an octal number" do
        pending "TODO WRITE THIS"
      end

      it "should set permissions in numeric form as a ruby-interpreted integer" do
        pending "TODO WRITE THIS"
      end
    end
  end
end
