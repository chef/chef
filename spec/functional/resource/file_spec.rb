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

describe Chef::Resource::File do
  include_context Chef::Resource::File

  let(:file_base) { "file_spec" }
  let(:expected_content) { "Don't fear the ruby." }

  def create_resource
    events = Chef::EventDispatch::Dispatcher.new
    node = Chef::Node.new
    run_context = Chef::RunContext.new(node, {}, events)
    resource = Chef::Resource::File.new(path, run_context)
    resource
  end

  let!(:resource) do
    r = create_resource
    r.content(expected_content)
    r
  end

  let(:resource_without_content) do
    create_resource
  end

  let(:unmanaged_content) do
    "This is file content that is not managed by chef"
  end

  let(:current_resource) do
    provider = resource.provider_for_action(resource.action)
    provider.load_current_resource
    provider.current_resource
  end

  it_behaves_like "a file resource"

  describe "reading file security metadata for reporting", :focus => true do
    context "when the target file doesn't exist" do
      before do
        resource.action(:create)
      end

      it "has empty values for file metadata in 'current_resource'" do
        current_resource.owner.should be_nil
        current_resource.group.should be_nil
        current_resource.mode.should be_nil
      end

      context "and no security metadata is specified in new_resource" do
        it "sets the metadata values on the new_resource as strings after creating" do
          resource.run_action(:create)
          # TODO: most stable way to specify?
          resource.owner.should == Etc.getpwuid(Process.uid).name
          resource.group.should == Etc.getgrgid(Process.gid).name
          resource.mode.should == (0100666 - File.umask).to_s(8)
        end
      end

      context "and owner is specified with a String (username) in new_resource", :requires_root => true do

        # TODO/bug: duplicated from the "securable resource" tests
        let(:expected_user_name) { 'nobody' }

        before do
          resource.owner(expected_user_name)
          resource.run_action(:create)
        end

        it "sets the owner on new_resource to the username (String) of the desired owner" do
          resource.owner.should == expected_user_name
        end

      end

      context "and owner is specified with an Integer (uid) in new_resource", :requires_root => true do

        # TODO: duplicated from "securable resource"
        let(:expected_user_name) { 'nobody' }
        let(:expected_uid) { Etc.getpwnam(expected_user_name).uid }
        let(:desired_gid) { 1337 }
        let(:expected_gid) { 1337 }

        before do
          resource.owner(expected_uid)
          resource.run_action(:create)
        end

        it "sets the owner on new_resource to the uid (Integer) of the desired owner" do
          resource.owner.should == expected_uid
        end
      end

      context "and group is specified with a String (group name)", :requires_root => true do

        let(:expected_group_name) { Etc.getgrent.name }

        before do
          resource.group(expected_group_name)
          resource.run_action(:create)
        end

        it "sets the group on new_resource to the group name (String) of the group" do
          resource.group.should == expected_group_name
        end

      end

      context "and group is specified with an Integer (gid)", :requires_root => true do
        let(:expected_gid) { Etc.getgrent.gid }

        before do
          resource.group(expected_gid)
          resource.run_action(:create)
        end

        it "sets the group on new_resource to the gid (Integer)" do
          resource.group.should == expected_gid
        end

      end

      context "and mode is specified as a String" do
        let(:expected_mode) { "0440" }

        before do
          resource.mode(expected_mode)
          resource.run_action(:create)
        end

        it "sets mode on the new_resource as a String" do
          resource.mode.should == expected_mode
        end
      end

      context "and mode is specified as an Integer" do
        let(:expected_mode) { 00440 }

        before do
          resource.mode(expected_mode)
          resource.run_action(:create)
        end

        it "sets mode on the new resource as an integer" do
          resource.mode.should == expected_mode
        end
      end
    end

    context "when the target file exists" do
      before do
        FileUtils.touch(resource.path)
        resource.action(:create)
      end

      context "and no security metadata is specified in new_resource" do
        it "sets the current values on current resource as strings" do
          # TODO: most stable way to specify?
          current_resource.owner.should == Etc.getpwuid(Process.uid).name
          current_resource.group.should == Etc.getgrgid(Process.gid).name
          current_resource.mode.should == (0100666 - File.umask).to_s(8)
        end
      end

      context "and owner is specified with a String (username) in new_resource" do

        let(:expected_user_name) { Etc.getpwuid(Process.uid).name }

        before do
          resource.owner(expected_user_name)
        end

        it "sets the owner on new_resource to the username (String) of the desired owner" do
          current_resource.owner.should == expected_user_name
        end

      end

      context "and owner is specified with an Integer (uid) in new_resource" do

        let(:expected_uid) { Process.uid }

        before do
          resource.owner(expected_uid)
        end

        it "sets the owner on new_resource to the uid (Integer) of the desired owner" do
          current_resource.owner.should == expected_uid
        end
      end

      context "and group is specified with a String (group name)" do

        let(:expected_group_name) { Etc.getgrgid(Process.gid).name }

        before do
          resource.group(expected_group_name)
        end

        it "sets the group on new_resource to the group name (String) of the group" do
          current_resource.group.should == expected_group_name
        end

      end

      context "and group is specified with an Integer (gid)" do
        let(:expected_gid) { Process.gid }

        before do
          resource.group(expected_gid)
        end

        it "sets the group on new_resource to the gid (Integer)" do
          current_resource.group.should == expected_gid
        end

      end

      context "and mode is specified as a String" do
        let(:expected_mode) { ((0100666 - File.umask) & 07777).to_s(8) }

        before do
          resource.mode(expected_mode)
        end

        it "sets mode on the new_resource as a String" do
          current_resource.mode.should == expected_mode
        end
      end

      context "and mode is specified as an Integer" do
        let(:expected_mode) { (0100666 - File.umask) & 07777 }

        before do
          resource.mode(expected_mode)
        end

        it "sets mode on the new resource as an integer" do
          current_resource.mode.should == expected_mode
        end
      end
    end
  end

  describe "when running action :touch" do
    context "and the target file does not exist" do
      before do
        resource.run_action(:touch)
      end

      it "it creates the file" do
        File.should exist(path)
      end

      it "is marked updated by last action" do
        resource.should be_updated_by_last_action
      end
    end

    context "and the target file exists and has the correct content" do
      before(:each) do
        File.open(path, "w") { |f| f.print expected_content }

        @expected_checksum = sha256_checksum(path)

        now = Time.now.to_i
        File.utime(now - 9000, now - 9000, path)
        @expected_mtime = File.stat(path).mtime

        resource.run_action(:touch)
      end

      it "updates the mtime of the file" do
        File.stat(path).mtime.should > @expected_mtime
      end

      it "does not change the content" do
        sha256_checksum(path).should == @expected_checksum
      end

      it "is marked as updated by last action" do
        resource.should be_updated_by_last_action
      end
    end
  end

end
