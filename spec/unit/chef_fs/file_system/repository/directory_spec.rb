#
# Author:: Thom May (<thom@chef.io>)
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

require "spec_helper"
require "chef/chef_fs/file_system/repository/directory"
require "chef/chef_fs/file_system/base_fs_object"
require "chef/chef_fs/file_system/exceptions"
require "chef/chef_fs/file_system/nonexistent_fs_object"

CHILD_FILES = %w{ test1.json test2.json skip test3.json skip2 test4 }.freeze

class TestDirectory < Chef::ChefFS::FileSystem::Repository::Directory
  def make_child_entry(name)
    TestFile.new(name, self)
  end

  def can_have_child?(name, is_dir)
    !is_dir && File.extname(name) == ".json"
  end

  def dir_ls
    CHILD_FILES
  end
end

class TestFile < Chef::ChefFS::FileSystem::BaseFSObject
  def fs_entry_valid?
    name.start_with? "test"
  end

  def name_valid?
    true
  end
end

describe Chef::ChefFS::FileSystem::Repository::Directory do
  let(:root) do
    Chef::ChefFS::FileSystem::BaseFSDir.new("", nil)
  end

  let(:tmp_dir) { Dir.mktmpdir }

  let(:directory) do
    described_class.new("test", root, tmp_dir)
  end

  let(:test_directory) do
    TestDirectory.new("test", root, tmp_dir)
  end

  let(:file_double) do
    double(TestFile, create: true, exist?: false, exists?: false)
  end

  context "#make_child_entry" do
    it "raises if not implemented" do
      expect { directory.send(:make_child_entry, "test") }.to raise_error("Not Implemented")
    end
  end

  context "#create_child" do
    it "creates a new TestFile" do
      expect(TestFile).to receive(:new).with("test_child", test_directory).and_return(file_double)
      allow(file_double).to receive(:file_path).and_return("#{test_directory}/test_child")
      expect(file_double).to receive(:write).with("test")
      test_directory.create_child("test_child", "test")
    end
  end

  context "#child" do
    it "returns a child if it's valid" do
      expect(test_directory.child("test")).to be_an_instance_of(TestFile)
    end

    it "returns a non existent object otherwise" do
      file_double = instance_double(TestFile, name_valid?: false)
      expect(TestFile).to receive(:new).with("test_child", test_directory).and_return(file_double)
      expect(test_directory.child("test_child")).to be_an_instance_of(Chef::ChefFS::FileSystem::NonexistentFSObject)
    end
  end

  context "#children" do
    before do
      CHILD_FILES.sort.each do |child|
        expect(TestFile).to receive(:new).with(child, test_directory).and_call_original
      end
    end

    it "creates a child for each name" do
      test_directory.children
    end

    it "filters invalid names" do
      expect(test_directory.children.map(&:name)).to eql %w{ test1.json test2.json test3.json }
    end
  end

  context "#empty?" do
    it "is true if there are no children" do
      expect(test_directory).to receive(:children).and_return([])
      expect(test_directory.empty?).to be_truthy
    end

    it "is false if there are children" do
      expect(test_directory.empty?).to be_falsey
    end
  end

  describe "checks entry validity" do
    it "rejects dotfiles" do
      dir = described_class.new(".test", root, tmp_dir)
      expect(dir.name_valid?).to be_falsey
    end

    it "rejects files" do
      Tempfile.open("test") do |file|
        dir = described_class.new("test", root, file.path)
        expect(dir.name_valid?).to be_truthy
        expect(dir.fs_entry_valid?).to be_falsey
      end
    end

    it "accepts directories" do
      expect(directory.name_valid?).to be_truthy
    end
  end

  describe "creates directories" do
    it "doesn't create an existing directory" do
      expect { directory.create }.to raise_error(Chef::ChefFS::FileSystem::AlreadyExistsError)
    end

    it "creates a new directory" do
      FileUtils.rmdir(tmp_dir)
      expect(Dir).to receive(:mkdir).with(tmp_dir)
      expect { directory.create }.to_not raise_error
    end

    after do
      FileUtils.rm_rf(tmp_dir)
    end
  end

  describe "deletes directories" do
    it "won't delete a non-existant directory" do
      FileUtils.rmdir(tmp_dir)
      expect { directory.delete(true) }.to raise_error(Chef::ChefFS::FileSystem::NotFoundError)
    end

    it "must delete recursively" do
      expect { directory.delete(false) }.to raise_error(Chef::ChefFS::FileSystem::MustDeleteRecursivelyError)
    end

    it "deletes a directory" do
      expect(FileUtils).to receive(:rm_r).with(tmp_dir)
      expect { directory.delete(true) }.to_not raise_error
    end
  end

end
