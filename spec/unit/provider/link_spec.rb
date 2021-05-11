#
# Author:: AJ Christensen (<aj@junglist.gen.nz>)
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "ostruct"

require "spec_helper"

if ChefUtils.windows?
  require "chef/win32/file" # probably need this in spec_helper
end

describe Chef::Resource::Link do
  let(:logger) { double("Mixlib::Log::Child").as_null_object }
  let(:provider) do
    node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, @events)
    allow(run_context).to receive(:logger).and_return(logger)
    Chef::Provider::Link.new(new_resource, run_context)
  end
  let(:new_resource) do
    result = Chef::Resource::Link.new("#{CHEF_SPEC_DATA}/fofile-link")
    result.to "#{CHEF_SPEC_DATA}/fofile"
    result
  end

  def canonicalize(path)
    ChefUtils.windows? ? path.tr("/", "\\") : path
  end

  describe "when the target is a symlink" do
    before(:each) do
      lstat = double("stats", ino: 5)
      allow(lstat).to receive(:uid).and_return(501)
      allow(lstat).to receive(:gid).and_return(501)
      allow(lstat).to receive(:mode).and_return(0777)
      allow(File).to receive(:lstat).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(lstat)
      allow(provider.file_class).to receive(:symlink?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(true)
      allow(provider.file_class).to receive(:readlink).with("#{CHEF_SPEC_DATA}/fofile-link").and_return("#{CHEF_SPEC_DATA}/fofile")
    end

    describe "to a file that exists" do
      before do
        allow(File).to receive(:exist?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(true)
        new_resource.owner 501 # only loaded in current_resource if present in new
        new_resource.group 501
        provider.load_current_resource
      end

      it "should set the symlink target" do
        expect(provider.current_resource.target_file).to eq("#{CHEF_SPEC_DATA}/fofile-link")
      end
      it "should set the link type" do
        expect(provider.current_resource.link_type).to eq(:symbolic)
      end
      it "should update the source of the existing link with the links target" do
        expect(provider.current_resource.to).to  eq(canonicalize("#{CHEF_SPEC_DATA}/fofile"))
      end
      it "should set the owner" do
        expect(provider.current_resource.owner).to eq(501)
      end
      it "should set the group" do
        expect(provider.current_resource.group).to eq(501)
      end

      # We test create in unit tests because there is no other way to ensure
      # it does no work.  Other create and delete scenarios are covered in
      # the functional tests for links.
      context "when the desired state is identical" do
        let(:new_resource) do
          result = Chef::Resource::Link.new("#{CHEF_SPEC_DATA}/fofile-link")
          result.to "#{CHEF_SPEC_DATA}/fofile"
          result
        end
        it "create does no work" do
          expect(provider.access_controls).not_to receive(:set_all)
          provider.run_action(:create)
        end
      end
    end

    describe "to a file that doesn't exist" do
      before do
        allow(File).to receive(:exist?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(false)
        allow(provider.file_class).to receive(:symlink?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(true)
        allow(provider.file_class).to receive(:readlink).with("#{CHEF_SPEC_DATA}/fofile-link").and_return("#{CHEF_SPEC_DATA}/fofile")
        new_resource.owner "501" # only loaded in current_resource if present in new
        new_resource.group "501"
        provider.load_current_resource
      end

      it "should set the symlink target" do
        expect(provider.current_resource.target_file).to eq("#{CHEF_SPEC_DATA}/fofile-link")
      end
      it "should set the link type" do
        expect(provider.current_resource.link_type).to eq(:symbolic)
      end
      it "should update the source of the existing link to the link's target" do
        expect(provider.current_resource.to).to eq(canonicalize("#{CHEF_SPEC_DATA}/fofile"))
      end
      it "should not set the owner" do
        expect(provider.current_resource.owner).to be_nil
      end
      it "should not set the group" do
        expect(provider.current_resource.group).to be_nil
      end
    end
  end

  describe "when the target doesn't exist" do
    before do
      allow(File).to receive(:exists?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(false)
      allow(provider.file_class).to receive(:symlink?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(false)
      provider.load_current_resource
    end

    it "should set the symlink target" do
      expect(provider.current_resource.target_file).to eq("#{CHEF_SPEC_DATA}/fofile-link")
    end
    it "should update the source of the existing link to nil" do
      expect(provider.current_resource.to).to be_nil
    end
    it "should not set the owner" do
      expect(provider.current_resource.owner).to eq(nil)
    end
    it "should not set the group" do
      expect(provider.current_resource.group).to eq(nil)
    end
  end

  describe "when the target is a regular old file" do
    before do
      stat = double("stats", ino: 5)
      allow(stat).to receive(:uid).and_return(501)
      allow(stat).to receive(:gid).and_return(501)
      allow(stat).to receive(:mode).and_return(0755)
      allow(provider.file_class).to receive(:stat).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(stat)

      allow(File).to receive(:exists?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(true)
      allow(provider.file_class).to receive(:symlink?).with("#{CHEF_SPEC_DATA}/fofile-link").and_return(false)
    end

    describe "and the source does not exist" do
      before do
        allow(File).to receive(:exists?).with("#{CHEF_SPEC_DATA}/fofile").and_return(false)
        provider.load_current_resource
      end

      it "should set the symlink target" do
        expect(provider.current_resource.target_file).to eq("#{CHEF_SPEC_DATA}/fofile-link")
      end
      it "should update the current source of the existing link with an empty string" do
        expect(provider.current_resource.to).to eq("")
      end
      it "should not set the owner" do
        expect(provider.current_resource.owner).to eq(nil)
      end
      it "should not set the group" do
        expect(provider.current_resource.group).to eq(nil)
      end
    end

    describe "and the source exists" do
      before do
        stat = double("stats", ino: 6)
        allow(stat).to receive(:uid).and_return(502)
        allow(stat).to receive(:gid).and_return(502)
        allow(stat).to receive(:mode).and_return(0644)

        allow(provider.file_class).to receive(:stat).with("#{CHEF_SPEC_DATA}/fofile").and_return(stat)

        allow(File).to receive(:exists?).with("#{CHEF_SPEC_DATA}/fofile").and_return(true)
        provider.load_current_resource
      end

      it "should set the symlink target" do
        expect(provider.current_resource.target_file).to eq("#{CHEF_SPEC_DATA}/fofile-link")
      end
      it "should update the current source of the existing link with an empty string" do
        expect(provider.current_resource.to).to eq("")
      end
      it "should not set the owner" do
        expect(provider.current_resource.owner).to eq(nil)
      end
      it "should not set the group" do
        expect(provider.current_resource.group).to eq(nil)
      end
    end

    describe "and is hardlinked to the source" do
      before do
        stat = double("stats", ino: 5)
        allow(stat).to receive(:uid).and_return(502)
        allow(stat).to receive(:gid).and_return(502)
        allow(stat).to receive(:mode).and_return(0644)

        allow(provider.file_class).to receive(:stat).with("#{CHEF_SPEC_DATA}/fofile").and_return(stat)

        allow(File).to receive(:exists?).with("#{CHEF_SPEC_DATA}/fofile").and_return(true)
        provider.load_current_resource
      end

      it "should set the symlink target" do
        expect(provider.current_resource.target_file).to eq("#{CHEF_SPEC_DATA}/fofile-link")
      end
      it "should set the link type" do
        expect(provider.current_resource.link_type).to eq(:hard)
      end
      it "should update the source of the existing link to the link's target" do
        expect(provider.current_resource.to).to eq(canonicalize("#{CHEF_SPEC_DATA}/fofile"))
      end
      it "should not set the owner" do
        expect(provider.current_resource.owner).to eq(nil)
      end
      it "should not set the group" do
        expect(provider.current_resource.group).to eq(nil)
      end

      # We test create in unit tests because there is no other way to ensure
      # it does no work.  Other create and delete scenarios are covered in
      # the functional tests for links.
      context "when the desired state is identical" do
        let(:new_resource) do
          result = Chef::Resource::Link.new("#{CHEF_SPEC_DATA}/fofile-link")
          result.to "#{CHEF_SPEC_DATA}/fofile"
          result.link_type :hard
          result
        end
        it "create does no work" do
          expect(provider.file_class).not_to receive(:symlink)
          expect(provider.file_class).not_to receive(:link)
          expect(provider.access_controls).not_to receive(:set_all)
          provider.run_action(:create)
        end
      end
    end
  end

  describe "action_delete" do
    before(:each) do
      stat = double("stats", ino: 5)
      allow(stat).to receive(:uid).and_return(501)
      allow(stat).to receive(:gid).and_return(501)
      allow(stat).to receive(:mode).and_return(0755)
      allow(provider.file_class).to receive(:stat).with(
        "#{CHEF_SPEC_DATA}/fofile-link"
      ).and_return(stat)

      provider.load_current_resource
    end

    shared_context "delete link to directories on Windows" do
      before do
        allow(::File).to receive(:directory?).with(
          "#{CHEF_SPEC_DATA}/fofile-link"
        ).and_return(true)
      end

      it "invokes Dir.delete method to delete the link" do
        expect(::Dir).to receive(:delete).with(provider.new_resource.target_file)
        expect(logger).to receive(:info).with("#{provider.new_resource} deleted")
        provider.run_action(:delete)
      end
    end

    shared_context "delete link to directories on Linux" do
      before do
        allow(::File).to receive(:directory?).with(
          "#{CHEF_SPEC_DATA}/fofile-link"
        ).and_return(true)
      end

      it "invokes File.delete method to delete the link" do
        expect(::File).to receive(:delete).with(provider.new_resource.target_file)
        expect(logger).to receive(:info).with("#{provider.new_resource} deleted")
        provider.run_action(:delete)
      end
    end

    shared_context "delete link to files" do
      before do
        allow(::File).to receive(:directory?).with(
          "#{CHEF_SPEC_DATA}/fofile-link"
        ).and_return(false)
      end

      it "invokes File.delete method to delete the link" do
        expect(::File).to receive(:delete).with(provider.new_resource.target_file)
        expect(logger).to receive(:info).with("#{provider.new_resource} deleted")
        provider.run_action(:delete)
      end
    end

    shared_context "soft links prerequisites" do
      before(:each) do
        allow(provider.file_class).to receive(:symlink?).with(
          "#{CHEF_SPEC_DATA}/fofile-link"
        ).and_return(true)
        allow(provider.file_class).to receive(:readlink).with(
          "#{CHEF_SPEC_DATA}/fofile-link"
        ).and_return("#{CHEF_SPEC_DATA}/fofile")
      end
    end

    shared_context "hard links prerequisites" do
      let(:new_resource) do
        result = Chef::Resource::Link.new("#{CHEF_SPEC_DATA}/fofile-link")
        result.to "#{CHEF_SPEC_DATA}/fofile"
        result.link_type :hard
        result
      end

      before(:each) do
        stat = double("stats", ino: 5)
        allow(stat).to receive(:uid).and_return(502)
        allow(stat).to receive(:gid).and_return(502)
        allow(stat).to receive(:mode).and_return(0644)

        allow(provider.file_class).to receive(:symlink?).with(
          "#{CHEF_SPEC_DATA}/fofile-link"
        ).and_return(false)

        allow(File).to receive(:exists?).with(
          "#{CHEF_SPEC_DATA}/fofile-link"
        ).and_return(true)
        allow(File).to receive(:exists?).with(
          "#{CHEF_SPEC_DATA}/fofile"
        ).and_return(true)

        allow(provider.file_class).to receive(:stat).with(
          "#{CHEF_SPEC_DATA}/fofile"
        ).and_return(stat)
      end
    end

    context "on Windows platform" do
      let(:resource_link) do
        Chef::Resource::Link.new(provider.new_resource.name)
      end

      before(:each) do
        allow(Chef::Resource::Link).to receive(:new).with(
          provider.new_resource.name
        ).and_return(resource_link)
        allow(ChefUtils).to receive(:windows?).and_return(true)
      end

      context "soft links" do
        include_context "soft links prerequisites"

        context "to directories" do
          include_context "delete link to directories on Windows"
        end

        context "to files" do
          include_context "delete link to files"
        end
      end

      context "hard links" do
        include_context "hard links prerequisites"

        context "to directories" do
          include_context "delete link to directories on Windows"
        end

        context "to files" do
          include_context "delete link to files"
        end
      end
    end

    context "on Linux platform" do
      before(:each) do
        allow(ChefUtils).to receive(:windows?).and_return(false)
      end

      context "soft links" do
        include_context "soft links prerequisites"

        context "to directories" do
          include_context "delete link to directories on Linux"
        end

        context "to files" do
          include_context "delete link to files"
        end
      end

      context "hard links" do
        include_context "hard links prerequisites"

        context "to directories" do
          include_context "delete link to directories on Linux"
        end

        context "to files" do
          include_context "delete link to files"
        end
      end
    end
  end
end
