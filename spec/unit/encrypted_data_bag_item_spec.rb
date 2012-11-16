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

module Version1Encryptor
  def self.encrypt_value(plaintext_data, key)
    data = plaintext_data.to_yaml

    cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    cipher.encrypt
    cipher.pkcs5_keyivgen(key)
    encrypted_bytes = cipher.update(data)
    encrypted_bytes << cipher.final
    Base64.encode64(encrypted_bytes)
  end
end

describe Chef::EncryptedDataBagItem::Encryptor  do

  describe "generating a random IV" do
    it "generates a new IV for each encryption pass" do
      encryptor1 = Chef::EncryptedDataBagItem::Encryptor.new({"foo" => "bar"}, "passwd")
      encryptor2 = Chef::EncryptedDataBagItem::Encryptor.new({"foo" => "bar"}, "passwd")

      # No API in ruby OpenSSL to get the iv it used for the encryption back
      # out. Instead we test if the encrypted data is the same. If it *is* the
      # same, we assume the IV was the same each time.
      encryptor1.encrypted_data.should_not == encryptor2.encrypted_data
    end
  end

  describe "when encrypting a non-hash non-array value" do
    it "serializes the value in a de-serializable way" do
      encryptor = Chef::EncryptedDataBagItem::Encryptor.new(5, "passwd")
      Chef::JSONCompat.from_json(encryptor.serialized_data)["json_wrapper"].should == 5
    end

  end

  describe "wrapping secret values in an envelope" do
    it "wraps the encrypted data in an envelope with the iv and version" do
      encryptor = Chef::EncryptedDataBagItem::Encryptor.new({"foo" => "bar"}, "passwd")
      final_data = encryptor.for_encrypted_item
      final_data["encrypted_data"].should == encryptor.encrypted_data
      final_data["iv"].should == Base64.encode64(encryptor.iv)
      final_data["version"].should == 1
      final_data["cipher"].should == "aes-256-cbc"
    end

  end

end

describe Chef::EncryptedDataBagItem::Decryptor do
  context "when decrypting a version 1 (JSON+aes-256-cbc+random iv) encrypted value" do
    before do
      @encryptor = Chef::EncryptedDataBagItem::Encryptor.new({"foo" => "bar"}, "passwd")
      @encrypted_value = @encryptor.for_encrypted_item

      @decryptor = Chef::EncryptedDataBagItem::Decryptor.for(@encrypted_value, "passwd")
    end

    it "selects the correct strategy for version 1" do
      @decryptor.should be_a_kind_of Chef::EncryptedDataBagItem::Decryptor::Version1Decryptor
    end

    it "decrypts the encrypted value" do
      @decryptor.decrypted_data.should == {"json_wrapper" => {"foo" => "bar"}}.to_json
    end

    it "unwraps the encrypted data and returns it" do
      @decryptor.for_decrypted_item.should == {"foo" => "bar"}
    end

    context "and the provided key is incorrect" do
      before do
        @decryptor = Chef::EncryptedDataBagItem::Decryptor.for(@encrypted_value, "wrong-passwd")
      end

      it "raises a sensible error" do
        lambda { @decryptor.for_decrypted_item }.should raise_error(Chef::EncryptedDataBagItem::DecryptionFailure)
      end
    end

    context "and the cipher is not supported" do
      before do
        @encrypted_value["cipher"] = "aes-256-foo"
      end

      it "raises a sensible error" do
        lambda { @decryptor.for_decrypted_item }.should raise_error(Chef::EncryptedDataBagItem::UnsupportedCipher)
      end
    end

  end

  context "when decrypting a version 0 (YAML+aes-256-cbc+no iv) encrypted value" do
    before do
      @encrypted_value = Version1Encryptor.encrypt_value({"foo" => "bar"}, "passwd")

      @decryptor = Chef::EncryptedDataBagItem::Decryptor.for(@encrypted_value, "passwd")
    end

    it "selects the correct strategy for version 0" do
      @decryptor.should be_a_kind_of(Chef::EncryptedDataBagItem::Decryptor::Version0Decryptor)
    end

    it "decrypts the encrypted value" do
      @decryptor.for_decrypted_item.should == {"foo" => "bar"}
    end
  end
end

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

    it "should encrypt non-collection objects" do
      @enc_data["greeting"]["version"].should == 1
      @enc_data["greeting"].should have_key("iv")

      iv = @enc_data["greeting"]["iv"]
      encryptor = Chef::EncryptedDataBagItem::Encryptor.new("hello", @secret, iv)

      @enc_data["greeting"]["encrypted_data"].should == encryptor.for_encrypted_item["encrypted_data"]
    end

    it "should encrypt nested values" do
      @enc_data["nested"]["version"].should == 1
      @enc_data["nested"].should have_key("iv")

      iv = @enc_data["nested"]["iv"]
      encryptor = Chef::EncryptedDataBagItem::Encryptor.new(@plain_data["nested"], @secret, iv)

      @enc_data["nested"]["encrypted_data"].should == encryptor.for_encrypted_item["encrypted_data"]
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
