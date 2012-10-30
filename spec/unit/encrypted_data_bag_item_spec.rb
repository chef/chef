#
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright 2010-2011 Opscode, Inc.
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
require 'chef/encrypted_data_bag_item'

describe Chef::EncryptedDataBagItem do
  before(:each) do
    @secret = "abc123SECRET"
    @plain_data = {
      "id" => "item_name",
      "greeting" => "hello",
      "nested" => { "a1" => [1, 2, 3], "a2" => { "b1" => true }}
    }
    @enc_data = Chef::EncryptedDataBagItem.encrypt_data_bag_item(@plain_data,
                                                                 @secret)
  end

  describe "encrypting" do

    it "should not encrypt the 'id' key" do
      @enc_data["id"].should == "item_name"
    end

    it "should encrypt 'greeting'" do
      @enc_data["greeting"].should_not == @plain_data["greeting"]
    end

    it "should encrypt 'nested'" do
      nested = @enc_data["nested"]
      nested.class.should == String
      nested.should_not == @plain_data["nested"]
    end

    it "from_plain_hash" do
      eh1 = Chef::EncryptedDataBagItem.from_plain_hash(@plain_data, @secret)
      eh1.class.should == Chef::EncryptedDataBagItem
    end
  end

  describe "decrypting" do
    before(:each) do
      @enc_data = Chef::EncryptedDataBagItem.encrypt_data_bag_item(@plain_data,
                                                                   @secret)
      @eh = Chef::EncryptedDataBagItem.new(@enc_data, @secret)
    end

    it "doesn't try to decrypt 'id'" do
      @eh["id"].should == @plain_data["id"]
    end

    it "decrypts 'greeting'" do
      @eh["greeting"].should == @plain_data["greeting"]
    end

    it "decrypts 'nested'" do
      @eh["nested"].should == @plain_data["nested"]
    end

    it "decrypts everyting via to_hash" do
      @eh.to_hash.should == @plain_data
    end

    it "handles missing keys gracefully" do
      @eh["no-such-key"].should be_nil
    end
  end

  describe "loading" do
    it "should defer to Chef::DataBagItem.load" do
      Chef::DataBagItem.stub(:load).with(:the_bag, "my_codes").and_return(@enc_data)
      edbi = Chef::EncryptedDataBagItem.load(:the_bag, "my_codes", @secret)
      edbi["greeting"].should == @plain_data["greeting"]
    end
  end

  describe "load_secret" do
    it "should read from the default path" do
      default_path = "/etc/chef/encrypted_data_bag_secret"
      ::File.stub(:exists?).with(default_path).and_return(true)
      IO.stub(:read).with(default_path).and_return("opensesame")
      Chef::EncryptedDataBagItem.load_secret().should == "opensesame"
    end

    it "should read from Chef::Config[:encrypted_data_bag_secret]" do
      path = "/var/mysecret"
      Chef::Config[:encrypted_data_bag_secret] = path
      ::File.stub(:exists?).with(path).and_return(true)
      IO.stub(:read).with(path).and_return("opensesame")
      Chef::EncryptedDataBagItem.load_secret().should == "opensesame"
    end

    it "should read from a specified path" do
      path = "/var/mysecret"
      ::File.stub(:exists?).with(path).and_return(true)
      IO.stub(:read).with(path).and_return("opensesame")
      Chef::EncryptedDataBagItem.load_secret(path).should == "opensesame"
    end

    it "should read from a URL" do
      path = "http://www.opscode.com/"
      fake_file = StringIO.new("opensesame")
      Kernel.stub(:open).with(path).and_return(fake_file)
      Chef::EncryptedDataBagItem.load_secret(path).should == "opensesame"
    end
  end
end
