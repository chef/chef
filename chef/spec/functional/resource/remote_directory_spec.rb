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

  let!(:resource) do
    create_resource
  end

  it_behaves_like "a directory resource"

  context "when creating the remote directory" do
    it "transfers the directory with all contents" do
      resource.run_action(:create)
      File.should exist(File.join(path, 'remote_dir_file1.txt'))
      File.should exist(File.join(path, 'remote_dir_file2.txt'))
      File.should exist(File.join(path, 'remotesubdir', 'remote_subdir_file1.txt'))
      File.should exist(File.join(path, 'remotesubdir', 'remote_subdir_file2.txt'))
      File.should exist(File.join(path, 'remotesubdir', '.a_dotfile'))
      File.should exist(File.join(path, '.a_dotdir', '.a_dotfile_in_a_dotdir'))
    end

    context "with purging enabled" do
      before(:each) do
        resource.purge(true)
      end

      it "removes existing files if purge is true" do
        FileUtils.mkdir_p(File.join(path, 'remotesubdir'))
        existing1 = File.join(path, 'marked_for_death.txt')
        existing2 = File.join(path, 'remotesubdir', 'marked_for_death_again.txt')
        FileUtils.touch(existing1)
        FileUtils.touch(existing2)

        resource.run_action(:create)
        File.should_not exist(existing1)
        File.should_not exist(existing2)
      end

      it "removes files in subdirectories before files above" do
        FileUtils.mkdir_p(File.join(path, 'a', 'multiply', 'nested', 'directory'))
        existing1 = File.join(path, 'a', 'foo.txt')
        existing2 = File.join(path, 'a', 'multiply', 'bar.txt')
        existing3 = File.join(path, 'a', 'multiply', 'nested', 'baz.txt')
        existing4 = File.join(path, 'a', 'multiply', 'nested', 'directory', 'qux.txt')
        FileUtils.touch(existing1)
        FileUtils.touch(existing2)
        FileUtils.touch(existing3)
        FileUtils.touch(existing4)

        resource.run_action(:create)
        File.should_not exist(existing1)
        File.should_not exist(existing2)
        File.should_not exist(existing3)
        File.should_not exist(existing4)
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
end
