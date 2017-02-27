#
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

require "spec_helper"
require "chef/chef_fs/file_system/repository/base_file"
require "chef/chef_fs/file_system/repository/directory"
require "chef/chef_fs/file_system/base_fs_object"
require "chef/chef_fs/file_system/exceptions"
require "chef/chef_fs/file_system/nonexistent_fs_object"

describe Chef::ChefFS::FileSystem::Repository::BaseFile do
  let(:root) do
    Chef::ChefFS::FileSystem::BaseFSDir.new("", nil)
  end

  let(:tmp_dir) { Dir.mktmpdir }

  let(:parent) do
    Chef::ChefFS::FileSystem::Repository::Directory.new("test", root, tmp_dir)
  end

  let(:file) do
    file = described_class.new("test_file.json", parent)
    file.write_pretty_json = false
    file
  end

  let(:content) { '"name": "canteloup"' }
  let(:file_path) { File.join(tmp_dir, "test_file.json") }

  after do
    FileUtils.rm_f(file_path)
  end

  context "#is_json_file?" do
    it "returns false when the file is not json", pending: "We assume that everything is ruby or JSON" do
      file = described_class.new("test_file.dpkg", parent)
      expect(file.is_json_file?).to be_falsey
    end

    it "returns true when the file is json" do
      expect(file.is_json_file?).to be_truthy
    end
  end

  context "#name_valid?" do
    it "rejects dotfiles" do
      file = described_class.new(".test_file.json", parent)
      expect(file.name_valid?).to be_falsey
    end

    it "rejects non json files", pending: "We assume that everything is ruby or JSON" do
      file = described_class.new("test_file.dpkg", parent)
      expect(file.name_valid?).to be_falsey
    end

    it "allows ruby files" do
      file = described_class.new("test_file.rb", parent)
      expect(file.name_valid?).to be_truthy
    end

    it "allows correctly named files" do
      expect(file.name_valid?).to be_truthy
    end
  end

  context "#fs_entry_valid?" do
    it "rejects invalid names" do
      file = described_class.new("test_file.dpkg", parent)
      expect(file.fs_entry_valid?).to be_falsey
    end

    it "rejects missing files" do
      FileUtils.rm_f(file_path)
      expect(file.fs_entry_valid?).to be_falsey
    end

    it "allows present and properly named files" do
      FileUtils.touch(file_path)
      expect(file.fs_entry_valid?).to be_truthy
    end
  end

  context "#create" do
    it "doesn't create an existing file" do
      FileUtils.touch(file_path)
      expect { file.create('"name": "canteloup"') }.to raise_error(Chef::ChefFS::FileSystem::AlreadyExistsError)
    end

    it "creates a new file" do
      expect(file).to receive(:write).with(content)
      expect { file.create(content) }.to_not raise_error
    end

  end

  context "#write" do
    context "minimises a json object" do
      it "unless pretty json is off" do
        expect(file).to_not receive(:minimize)
        file.write(content)
      end

      it "correctly" do
        file = described_class.new("test_file.json", parent)
        file.write_pretty_json = true
        expect(file).to receive(:minimize).with(content, file).and_return(content)
        file.write(content)
      end
    end
  end
end
