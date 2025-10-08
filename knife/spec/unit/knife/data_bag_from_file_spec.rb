#
# Author:: Seth Falcon (<seth@chef.io>)
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

require "knife_spec_helper"

require "chef/data_bag_item"
require "chef/encrypted_data_bag_item"
require "tempfile"

Chef::Knife::DataBagFromFile.load_deps

describe Chef::Knife::DataBagFromFile do
  before :each do
    allow(ChefUtils).to receive(:windows?) { false }
    Chef::Config[:node_name] = "webmonkey.example.com"
    FileUtils.mkdir_p([db_folder, db_folder2])
    db_file.write(Chef::JSONCompat.to_json(plain_data))
    db_file.flush
    allow(knife).to receive(:config).and_return(config)
    allow(Chef::Knife::Core::ObjectLoader).to receive(:new).and_return(loader)
  end

  # We have to explicitly clean up Tempfile on Windows because it said so.
  after :each do
    db_file.close
    db_file2.close
    db_file3.close
    FileUtils.rm_rf(db_folder)
    FileUtils.rm_rf(db_folder2)
    FileUtils.remove_entry_secure tmp_dir
  end

  let(:knife) do
    k = Chef::Knife::DataBagFromFile.new
    allow(k).to receive(:rest).and_return(rest)
    allow(k.ui).to receive(:stdout).and_return(stdout)
    k
  end

  let(:tmp_dir) { make_canonical_temp_directory }
  let(:db_folder) { File.join(tmp_dir, data_bags_path, bag_name) }
  let(:db_file) { Tempfile.new(["data_bag_from_file_test", ".json"], db_folder) }
  let(:db_file2) { Tempfile.new(["data_bag_from_file_test2", ".json"], db_folder) }
  let(:db_folder2) { File.join(tmp_dir, data_bags_path, bag_name2) }
  let(:db_file3) { Tempfile.new(["data_bag_from_file_test3", ".json"], db_folder2) }

  def new_bag_expects(b = bag_name, d = plain_data)
    data_bag = double
    expect(data_bag).to receive(:data_bag).with(b)
    expect(data_bag).to receive(:raw_data=).with(d)
    expect(data_bag).to receive(:save)
    expect(data_bag).to receive(:data_bag)
    expect(data_bag).to receive(:id)
    data_bag
  end

  let(:loader) { double("Knife::Core::ObjectLoader") }

  let(:data_bags_path) { "data_bags" }
  let(:plain_data) do
    {
      "id" => "item_name",
      "greeting" => "hello",
      "nested" => { "a1" => [1, 2, 3], "a2" => { "b1" => true } },
  }
  end
  let(:enc_data) { Chef::EncryptedDataBagItem.encrypt_data_bag_item(plain_data, secret) }

  let(:rest) { double("Chef::ServerAPI") }
  let(:stdout) { StringIO.new }

  let(:bag_name) { "sudoing_admins" }
  let(:bag_name2) { "sudoing_admins2" }
  let(:item_name) { "ME" }

  let(:secret) { "abc123SECRET" }

  let(:config) { {} }

  it "loads from a file and saves" do
    knife.name_args = [bag_name, db_file.path]
    expect(loader).to receive(:load_from).with(data_bags_path, bag_name, db_file.path).and_return(plain_data)
    expect(Chef::DataBagItem).to receive(:new).and_return(new_bag_expects)

    knife.run
  end

  it "loads all from multiple files and saves" do
    knife.name_args = [ bag_name, db_file.path, db_file2.path ]
    expect(loader).to receive(:load_from).with(data_bags_path, bag_name, db_file.path).and_return(plain_data)
    expect(loader).to receive(:load_from).with(data_bags_path, bag_name, db_file2.path).and_return(plain_data)
    expect(Chef::DataBagItem).to receive(:new).twice.and_return(new_bag_expects, new_bag_expects)

    knife.run
  end

  it "loads all from a folder and saves" do
    knife.name_args = [ bag_name, db_folder ]
    expect(loader).to receive(:load_from).with(data_bags_path, bag_name, db_file.path).and_return(plain_data)
    expect(loader).to receive(:load_from).with(data_bags_path, bag_name, db_file2.path).and_return(plain_data)
    expect(Chef::DataBagItem).to receive(:new).twice.and_return(new_bag_expects, new_bag_expects)

    knife.run
  end

  describe "loading all data bags" do

    it "loads all data bags when -a or --all options is provided" do
      knife.name_args = []
      config[:all] = true
      expect(loader).to receive(:find_all_object_dirs).with("./#{data_bags_path}").and_return([bag_name, bag_name2])
      expect(loader).to receive(:find_all_objects).with("./#{data_bags_path}/#{bag_name}").and_return([File.basename(db_file.path), File.basename(db_file2.path)])
      expect(loader).to receive(:find_all_objects).with("./#{data_bags_path}/#{bag_name2}").and_return([File.basename(db_file3.path)])
      expect(loader).to receive(:load_from).with(data_bags_path, bag_name, File.basename(db_file.path)).and_return(plain_data)
      expect(loader).to receive(:load_from).with(data_bags_path, bag_name, File.basename(db_file2.path)).and_return(plain_data)
      expect(loader).to receive(:load_from).with(data_bags_path, bag_name2, File.basename(db_file3.path)).and_return(plain_data)
      expect(Chef::DataBagItem).to receive(:new).exactly(3).times.and_return(new_bag_expects, new_bag_expects, new_bag_expects(bag_name2))

      knife.run
    end

    it "loads all data bags items when -a or --all options is provided" do
      knife.name_args = [bag_name2]
      config[:all] = true
      expect(loader).to receive(:find_all_objects).with("./#{data_bags_path}/#{bag_name2}").and_return([File.basename(db_file3.path)])
      expect(loader).to receive(:load_from).with(data_bags_path, bag_name2, File.basename(db_file3.path)).and_return(plain_data)
      expect(Chef::DataBagItem).to receive(:new).and_return(new_bag_expects(bag_name2))

      knife.run
    end

  end

  describe "encrypted data bag items" do
    before(:each) do
      expect(knife).to receive(:encryption_secret_provided?).and_return(true)
      expect(knife).to receive(:read_secret).and_return(secret)
      expect(Chef::EncryptedDataBagItem).to receive(:encrypt_data_bag_item).with(plain_data, secret).and_return(enc_data)
    end

    it "encrypts values when given --secret" do
      knife.name_args = [bag_name, db_file.path]
      expect(loader).to receive(:load_from).with(data_bags_path, bag_name, db_file.path).and_return(plain_data)
      expect(Chef::DataBagItem).to receive(:new).and_return(new_bag_expects(bag_name, enc_data))

      knife.run
    end

  end

  describe "command line parsing" do
    it "prints help if given no arguments" do
      knife.name_args = [bag_name]
      expect { knife.run }.to exit_with_code(1)
      expect(stdout.string).to start_with("knife data bag from file BAG FILE|FOLDER [FILE|FOLDER..] (options)")
    end
  end

end
