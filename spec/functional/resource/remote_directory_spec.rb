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

describe Chef::Resource::RemoteDirectory do
  include_context Chef::Resource::Directory

  let(:directory_base) { "directory_spec" }
  let(:default_mode) { "755" }

  def create_resource
    cookbook_repo = File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks"))
    Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::FileSystemFileVendor.new(manifest, cookbook_repo) }
    node = Chef::Node.new
    cl = Chef::CookbookLoader.new(cookbook_repo)
    cl.load_cookbooks
    cookbook_collection = Chef::CookbookCollection.new(cl)
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, cookbook_collection, events)

    resource = Chef::Resource::RemoteDirectory.new(path, run_context)
    resource.source "remotedir"
    resource.cookbook('openldap')
    resource
  end

  def create_extraneous_files
    FileUtils.mkdir_p(File.join(path, 'remotesubdir'))
    @existing1 = File.join(path, 'marked_for_death.txt')
    @existing2 = File.join(path, 'remotesubdir', 'marked_for_death_again.txt')
    FileUtils.touch(@existing1)
    FileUtils.touch(@existing2)
  end

  let!(:resource) do
    create_resource
  end

  let(:resource_second_pass) do
    create_resource
  end

  # See spec/data/cookbooks/openldap/files/default
  let(:expected_files) do
    [
      File.join(path, 'remote_dir_file1.txt'),
      File.join(path, 'remote_dir_file2.txt'),
      File.join(path, 'remotesubdir', 'remote_subdir_file1.txt'),
      File.join(path, 'remotesubdir', 'remote_subdir_file2.txt'),
      File.join(path, 'remotesubdir', '.a_dotfile'),
      File.join(path, '.a_dotdir', '.a_dotfile_in_a_dotdir')
    ]
  end

  it_behaves_like "a directory resource"

  it_behaves_like "a securable resource with reporting"

  context "when creating the remote directory with purging disabled" do

    context "and the directory does not yet exist" do
      before do
        resource.run_action(:create)
      end

      it "transfers the directory with all contents" do
        expected_files.each do |file_path|
          File.should exist(file_path)
        end
      end

      it "is marked as updated by last action" do
        resource.should be_updated_by_last_action
      end
    end

    context "and there are extraneous files in the directory" do
      before do
        create_extraneous_files
        resource.run_action(:create)
      end

      it "does not modify the expected state of the directory" do
        expected_files.each do |file_path|
          File.should exist(file_path)
        end
      end

      it "does not remove unmanaged files" do
        File.should exist(@existing1)
        File.should exist(@existing2)
      end
    end

    context "and the directory is in the desired state" do
      before do
        resource.run_action(:create)
        resource_second_pass.run_action(:create)
      end

      it "does not modify the expected state of the directory" do
        expected_files.each do |file_path|
          File.should exist(file_path)
        end
      end

      it "is not marked as updated by last action" do
        resource_second_pass.should_not be_updated_by_last_action
      end

    end

    describe "with overwrite disabled" do
      before(:each) do
        resource.purge(false)
        resource.overwrite(false)
      end

      it "leaves modifications alone" do
        FileUtils.mkdir_p(File.join(path, 'remotesubdir'))
        modified_file = File.join(path, 'remote_dir_file1.txt')
        modified_subdir_file = File.join(path, 'remotesubdir', 'remote_subdir_file1.txt')
        File.open(modified_file, 'a') {|f| f.puts "santa is real"}
        File.open(modified_subdir_file, 'a') {|f| f.puts "so is rudolph"}
        modified_file_checksum = sha256_checksum(modified_file)
        modified_subdir_file_checksum = sha256_checksum(modified_subdir_file)

        resource.run_action(:create)
        sha256_checksum(modified_file).should == modified_file_checksum
        sha256_checksum(modified_subdir_file).should == modified_subdir_file_checksum
      end
    end
  end

  context "when creating the directory with purging enabled" do
    before(:each) do
      resource.purge(true)
    end

    context "and there are no extraneous files in the directory" do
      before do
        resource.run_action(:create)
      end

      it "creates the directory contents as normal" do
        expected_files.each do |file_path|
          File.should exist(file_path)
        end
      end

    end

    context "and there are extraneous files in the directory" do
      before do
        create_extraneous_files
        resource.run_action(:create)
      end

      it "removes unmanaged files" do
        File.should_not exist(@existing1)
        File.should_not exist(@existing2)
      end

      it "does not modify managed files" do
        expected_files.each do |file_path|
          File.should exist(file_path)
        end
      end

      it "is marked as updated by last action" do
        resource.should be_updated_by_last_action
      end
    end

    context "and there are deeply nested extraneous files in the directory" do
      before do
        FileUtils.mkdir_p(File.join(path, 'a', 'multiply', 'nested', 'directory'))
        @existing1 = File.join(path, 'a', 'foo.txt')
        @existing2 = File.join(path, 'a', 'multiply', 'bar.txt')
        @existing3 = File.join(path, 'a', 'multiply', 'nested', 'baz.txt')
        @existing4 = File.join(path, 'a', 'multiply', 'nested', 'directory', 'qux.txt')
        FileUtils.touch(@existing1)
        FileUtils.touch(@existing2)
        FileUtils.touch(@existing3)
        FileUtils.touch(@existing4)

        resource.run_action(:create)
      end

      it "removes files in subdirectories before files above" do
        File.should_not exist(@existing1)
        File.should_not exist(@existing2)
        File.should_not exist(@existing3)
        File.should_not exist(@existing4)
      end

      it "is marked as updated by last action" do
        resource.should be_updated_by_last_action
      end

    end
  end

end
