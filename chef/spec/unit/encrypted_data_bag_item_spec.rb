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

module Version0Encryptor
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

# Encryption/serialization code from Chef 11.
class Version1Encryptor
  ALGORITHM = "aes-256-cbc"

  attr_reader :key
  attr_reader :plaintext_data

  # Create a new Encryptor for +data+, which will be encrypted with the given
  # +key+.
  #
  # === Arguments:
  # * data: An object of any type that can be serialized to json
  # * key: A String representing the desired passphrase
  # * iv: The optional +iv+ parameter is intended for testing use only. When
  # *not* supplied, Encryptor will use OpenSSL to generate a secure random
  # IV, which is what you want.
  def initialize(plaintext_data, key, iv=nil)
    @plaintext_data = plaintext_data
    @key = key
    @iv = iv && Base64.decode64(iv)
  end

  # Returns a wrapped and encrypted version of +plaintext_data+ suitable for
  # using as the value in an encrypted data bag item.
  def for_encrypted_item
    {
      "encrypted_data" => encrypted_data,
      "iv" => Base64.encode64(iv),
      "version" => 1,
      "cipher" => ALGORITHM
    }
  end

  # Generates or returns the IV.
  def iv
    # Generated IV comes from OpenSSL::Cipher::Cipher#random_iv
    # This gets generated when +openssl_encryptor+ gets created.
    openssl_encryptor if @iv.nil?
    @iv
  end

  # Generates (and memoizes) an OpenSSL::Cipher::Cipher object and configures
  # it for the specified iv and encryption key.
  def openssl_encryptor
    @openssl_encryptor ||= begin
      encryptor = OpenSSL::Cipher::Cipher.new(ALGORITHM)
      encryptor.encrypt
      @iv ||= encryptor.random_iv
      encryptor.iv = @iv
      encryptor.key = Digest::SHA256.digest(key)
      encryptor
    end
  end

  # Encrypts and Base64 encodes +serialized_data+
  def encrypted_data
    @encrypted_data ||= begin
      enc_data = openssl_encryptor.update(serialized_data)
      enc_data << openssl_encryptor.final
      Base64.encode64(enc_data)
    end
  end

  # Wraps the data in a single key Hash (JSON Object) and converts to JSON.
  # The wrapper is required because we accept values (such as Integers or
  # Strings) that do not produce valid JSON when serialized without the
  # wrapper.
  def serialized_data
    Chef::JSONCompat.to_json(:json_wrapper => plaintext_data)
  end
end


describe Chef::EncryptedDataBagItem::Decryptor do
  context "when decrypting a version 1 (JSON+aes-256-cbc+random iv) encrypted value" do
    before do
      @encryptor = Version1Encryptor.new({"foo" => "bar"}, "passwd")
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
      @encrypted_value = Version0Encryptor.encrypt_value({"foo" => "bar"}, "passwd")

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

    it "uses version 0 encryption/serialization" do
      @enc_data["greeting"].should == Version0Encryptor.encrypt_value(@plain_data["greeting"], @secret)
    end

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

  shared_examples_for "a decrypted data bag item" do

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

  describe "decrypting" do
    before(:each) do
      @enc_data = Chef::EncryptedDataBagItem.encrypt_data_bag_item(@plain_data,
                                                                   @secret)
      @eh = Chef::EncryptedDataBagItem.new(@enc_data, @secret)
    end

    it_behaves_like "a decrypted data bag item"
  end

  describe "when decrypting a version 1 (Chef 11.x) data bag item" do
    before do
      @enc_data = @plain_data.inject({}) do |encrypted, (key, value)|
        if key == "id"
          encrypted["id"] = value
        else
          encrypted[key] = Version1Encryptor.new(value, @secret).for_encrypted_item
        end
        encrypted
      end
      @eh = Chef::EncryptedDataBagItem.new(@enc_data, @secret)
    end

    it_behaves_like "a decrypted data bag item"
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
