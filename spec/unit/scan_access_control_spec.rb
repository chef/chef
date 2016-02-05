# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

require File.expand_path("../../spec_helper", __FILE__)
require "chef/scan_access_control"

describe Chef::ScanAccessControl do

  before do
    @new_resource = Chef::Resource::File.new("/tmp/foo/bar/baz/link")
    @real_file = "/tmp/foo/bar/real/file"
    @current_resource = Chef::Resource::File.new(@new_resource.path)
    @scanner = Chef::ScanAccessControl.new(@new_resource, @current_resource)
  end

  describe "when the fs entity does not exist" do

    before do
      @new_resource.tap do |f|
        f.owner("root")
        f.group("root")
        f.mode("0755")
      end
      @scanner.set_all!
    end

    it "does not set any fields on the current resource" do
      expect(@current_resource.owner).to be_nil
      expect(@current_resource.group).to be_nil
      expect(@current_resource.mode).to be_nil
    end

  end

  describe "when the fs entity exists" do

    before do
      @stat = double("File::Stat for #{@new_resource.path}", :uid => 0, :gid => 0, :mode => 00100644)
      expect(File).to receive(:realpath).with(@new_resource.path).and_return(@real_file)
      expect(File).to receive(:stat).with(@real_file).and_return(@stat)
      expect(File).to receive(:exist?).with(@new_resource.path).and_return(true)
    end

    describe "when new_resource does not specify mode, user or group" do
      # these tests are necessary for minitest-chef-handler to use as an API, see CHEF-3235
      before do
        @scanner.set_all!
      end

      it "sets the mode of the current resource to the current mode as a String" do
        expect(@current_resource.mode).to eq("0644")
      end

      context "on unix", :unix_only do
        it "sets the group of the current resource to the current group as a String" do
          expect(@current_resource.group).to eq(Etc.getgrgid(0).name)
        end

        it "sets the owner of the current resource to the current owner as a String" do
          expect(@current_resource.user).to eq("root")
        end
      end

      context "on windows", :windows_only do
        it "sets the group of the current resource to the current group as a String" do
          expect(@current_resource.group).to eq(0)
        end

        it "sets the owner of the current resource to the current owner as a String" do
          expect(@current_resource.user).to eq(0)
        end
      end
    end

    describe "when new_resource specifies the mode with a string" do
      before do
        @new_resource.mode("0755")
        @scanner.set_all!
      end

      it "sets the mode of the current resource to the file's current mode as a string" do
        expect(@current_resource.mode).to eq("0644")
      end
    end

    describe "when new_resource specified the mode with an integer" do
      before do
        @new_resource.mode(00755)
        @scanner.set_all!
      end

      it "sets the mode of the current resource to the current mode as a String" do
        expect(@current_resource.mode).to eq("0644")
      end

    end

    describe "when new_resource specifies the user with a UID" do

      before do
        @new_resource.user(0)
        @scanner.set_all!
      end

      it "sets the owner of current_resource to the UID of the current owner" do
        expect(@current_resource.user).to eq(0)
      end
    end

    describe "when new_resource specifies the user with a username" do

      before do
        @new_resource.user("root")
      end

      it "sets the owner of current_resource to the username of the current owner" do
        @root_passwd = double("Struct::Passwd for uid 0", :name => "root")
        expect(Etc).to receive(:getpwuid).with(0).and_return(@root_passwd)
        @scanner.set_all!

        expect(@current_resource.user).to eq("root")
      end

      describe "and there is no passwd entry for the user" do
        it "sets the owner of the current_resource to the UID" do
          expect(Etc).to receive(:getpwuid).with(0).and_raise(ArgumentError)
          @scanner.set_all!
          expect(@current_resource.user).to eq(0)
        end
      end
    end

    describe "when new_resource specifies the group with a GID" do

      before do
        @new_resource.group(0)
        @scanner.set_all!
      end

      it "sets the group of the current_resource to the gid of the current owner" do
        expect(@current_resource.group).to eq(0)
      end

    end

    describe "when new_resource specifies the group with a group name" do
      before do
        @new_resource.group("wheel")
      end

      it "sets the group of the current resource to the group name" do
        @group_entry = double("Struct::Group for wheel", :name => "wheel")
        expect(Etc).to receive(:getgrgid).with(0).and_return(@group_entry)
        @scanner.set_all!

        expect(@current_resource.group).to eq("wheel")
      end

      describe "and there is no group entry for the group" do
        it "sets the current_resource's group to the GID" do
          expect(Etc).to receive(:getgrgid).with(0).and_raise(ArgumentError)
          @scanner.set_all!
          expect(@current_resource.group).to eq(0)
        end
      end

    end
  end
end
