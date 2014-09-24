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

    cipher = OpenSSL::Cipher.new("aes-256-cbc")
    cipher.encrypt
    cipher.pkcs5_keyivgen(key)
    encrypted_bytes = cipher.update(data)
    encrypted_bytes << cipher.final
    Base64.encode64(encrypted_bytes)
  end
end

describe Chef::EncryptedDataBagItem::Encryptor  do

  subject(:encryptor) { described_class.new(plaintext_data, key) }
  let(:plaintext_data) { {"foo" => "bar"} }
  let(:key) { "passwd" }

  it "encrypts to format version 1 by default" do
    encryptor.should be_a_instance_of(Chef::EncryptedDataBagItem::Encryptor::Version1Encryptor)
  end

  describe "generating a random IV" do
    it "generates a new IV for each encryption pass" do
      encryptor2 = Chef::EncryptedDataBagItem::Encryptor.new(plaintext_data, key)

      # No API in ruby OpenSSL to get the iv is used for the encryption back
      # out. Instead we test if the encrypted data is the same. If it *is* the
      # same, we assume the IV was the same each time.
      encryptor.encrypted_data.should_not eq encryptor2.encrypted_data
    end
  end

  describe "when encrypting a non-hash non-array value" do
    let(:plaintext_data) { 5 }
    it "serializes the value in a de-serializable way" do
      Chef::JSONCompat.from_json(encryptor.serialized_data)["json_wrapper"].should eq 5
    end

  end

  describe "wrapping secret values in an envelope" do
    it "wraps the encrypted data in an envelope with the iv and version" do
      final_data = encryptor.for_encrypted_item
      final_data["encrypted_data"].should eq encryptor.encrypted_data
      final_data["iv"].should eq Base64.encode64(encryptor.iv)
      final_data["version"].should eq 1
      final_data["cipher"].should eq"aes-256-cbc"
    end
  end

  describe "when using version 2 format" do

    before do
      Chef::Config[:data_bag_encrypt_version] = 2
    end

    it "creates a version 2 encryptor" do
      encryptor.should be_a_instance_of(Chef::EncryptedDataBagItem::Encryptor::Version2Encryptor)
    end

    it "generates an hmac based on ciphertext with different iv" do
      encryptor2 = Chef::EncryptedDataBagItem::Encryptor.new(plaintext_data, key)
      encryptor.hmac.should_not eq(encryptor2.hmac)
    end

    it "includes the hmac in the envelope" do
      final_data = encryptor.for_encrypted_item
      final_data["hmac"].should eq(encryptor.hmac)
    end
  end

  describe "when using version 3 format" do
    before do
      Chef::Config[:data_bag_encrypt_version] = 3
    end

    context "on supported platforms", :ruby_gte_20_and_openssl_gte_101 do

      it "creates a version 3 encryptor" do
        encryptor.should be_a_instance_of(Chef::EncryptedDataBagItem::Encryptor::Version3Encryptor)
      end

      it "generates different authentication tags" do
        encryptor3 = Chef::EncryptedDataBagItem::Encryptor.new(plaintext_data, key)
        encryptor.for_encrypted_item # required to generate the auth_tag
        encryptor3.for_encrypted_item
        encryptor.auth_tag.should_not eq(encryptor3.auth_tag)
      end

      it "includes the auth_tag in the envelope" do
        final_data = encryptor.for_encrypted_item
        final_data["auth_tag"].should eq(Base64::encode64(encryptor.auth_tag))
      end

      it "throws an error if auth tag is read before encrypting the data" do
        lambda { encryptor.auth_tag }.should raise_error(Chef::EncryptedDataBagItem::EncryptionFailure)
      end

    end # context on supported platforms

    context "on unsupported platforms" do
      let(:aead_algorithm) { Chef::EncryptedDataBagItem::AEAD_ALGORITHM }

      it "throws an error warning about the Ruby version if it has no GCM support" do
        # Force OpenSSL with AEAD support
        OpenSSL::Cipher.stub(:ciphers).and_return([ aead_algorithm ])
        # Ruby without AEAD support
        OpenSSL::Cipher.should_receive(:method_defined?).with(:auth_data=).and_return(false)
        lambda { encryptor }.should raise_error(Chef::EncryptedDataBagItem::EncryptedDataBagRequirementsFailure, /requires Ruby/)
      end

      it "throws an error warning about the OpenSSL version if it has no GCM support" do
        # Force Ruby with AEAD support
        OpenSSL::Cipher.stub(:method_defined?).with(:auth_data=).and_return(true)
        # OpenSSL without AEAD support
        OpenSSL::Cipher.should_receive(:ciphers).and_return([])
        lambda { encryptor }.should raise_error(Chef::EncryptedDataBagItem::EncryptedDataBagRequirementsFailure, /requires an OpenSSL/)
      end

      context "on platforms with old Ruby", :ruby_lt_20 do

        it "throws an error warning about the Ruby version" do
          lambda { encryptor }.should raise_error(Chef::EncryptedDataBagItem::EncryptedDataBagRequirementsFailure, /requires Ruby/)
        end

      end # context on platforms with old Ruby

      context "on platforms with old OpenSSL", :openssl_lt_101 do

        it "throws an error warning about the OpenSSL version" do
          lambda { encryptor }.should raise_error(Chef::EncryptedDataBagItem::EncryptedDataBagRequirementsFailure, /requires an OpenSSL/)
        end

      end # context on platforms with old OpenSSL

    end # context on unsupported platforms

  end # when using version 3 format

end

describe Chef::EncryptedDataBagItem::Decryptor do

  subject(:decryptor) { described_class.for(encrypted_value, decryption_key) }
  let(:plaintext_data) { {"foo" => "bar"} }
  let(:encryption_key) { "passwd" }
  let(:decryption_key) { encryption_key }
  let(:json_wrapped_data) {  Chef::JSONCompat.to_json({"json_wrapper" => plaintext_data}) }

  shared_examples "decryption examples" do
    it "decrypts the encrypted value" do
      decryptor.decrypted_data.should eq(json_wrapped_data)
    end

    it "unwraps the encrypted data and returns it" do
      decryptor.for_decrypted_item.should eq plaintext_data
    end
  end

  context "when decrypting a version 3 (JSON+aes-256-gcm+random iv+auth tag) encrypted value" do

    context "on supported platforms", :ruby_gte_20_and_openssl_gte_101 do

      let(:encrypted_value) do
        Chef::EncryptedDataBagItem::Encryptor::Version3Encryptor.new(plaintext_data, encryption_key).for_encrypted_item
      end

      let(:bogus_auth_tag) { "bogus_auth_tag" }

      include_examples "decryption examples"

      it "rejects the data if the authentication tag is wrong" do
        encrypted_value["auth_tag"] = bogus_auth_tag
        lambda { decryptor.for_decrypted_item }.should raise_error(Chef::EncryptedDataBagItem::DecryptionFailure)
      end

      it "rejects the data if the authentication tag is missing" do
        encrypted_value.delete("auth_tag")
        lambda { decryptor.for_decrypted_item }.should raise_error(Chef::EncryptedDataBagItem::DecryptionFailure)
      end

    end # context on supported platforms

    context "on unsupported platforms" do
      let(:encrypted_value) do
        {
          "encrypted_data" => "",
          "iv" => "",
          "version" => 3,
          "cipher" => "aes-256-cbc",
        }
      end

      context "on platforms with old Ruby", :ruby_lt_20 do

        it "throws an error warning about the Ruby version" do
          lambda { decryptor }.should raise_error(Chef::EncryptedDataBagItem::EncryptedDataBagRequirementsFailure, /requires Ruby/)
        end

      end # context on platforms with old Ruby

      context "on platforms with old OpenSSL", :openssl_lt_101 do

        it "throws an error warning about the OpenSSL version" do
          lambda { decryptor }.should raise_error(Chef::EncryptedDataBagItem::EncryptedDataBagRequirementsFailure, /requires an OpenSSL/)
        end

      end # context on unsupported platforms

    end # context on platforms with old OpenSSL

  end # context when decrypting a version 3

  context "when decrypting a version 2 (JSON+aes-256-cbc+hmac-sha256+random iv) encrypted value" do
    let(:encrypted_value) do
      Chef::EncryptedDataBagItem::Encryptor::Version2Encryptor.new(plaintext_data, encryption_key).for_encrypted_item
    end

    let(:bogus_hmac) do
      digest = OpenSSL::Digest.new("sha256")
      raw_hmac = OpenSSL::HMAC.digest(digest, "WRONG", encrypted_value["encrypted_data"])
      Base64.encode64(raw_hmac)
    end

    include_examples "decryption examples"

    it "rejects the data if the hmac is wrong" do
      encrypted_value["hmac"] = bogus_hmac
      lambda { decryptor.for_decrypted_item }.should raise_error(Chef::EncryptedDataBagItem::DecryptionFailure)
    end

    it "rejects the data if the hmac is missing" do
      encrypted_value.delete("hmac")
      lambda { decryptor.for_decrypted_item }.should raise_error(Chef::EncryptedDataBagItem::DecryptionFailure)
    end

  end

  context "when decrypting a version 1 (JSON+aes-256-cbc+random iv) encrypted value" do

    let(:encrypted_value) do
      Chef::EncryptedDataBagItem::Encryptor.new(plaintext_data, encryption_key).for_encrypted_item
    end

    it "selects the correct strategy for version 1" do
      decryptor.should be_a_instance_of Chef::EncryptedDataBagItem::Decryptor::Version1Decryptor
    end

    include_examples "decryption examples"

    describe "and the decryption step returns invalid data" do
      it "raises a decryption failure error" do
        # Over a large number of tests on a variety of systems, we occasionally
        # see the decryption step "succeed" but return invalid data (e.g., not
        # the original plain text) [CHEF-3858]
        decryptor.should_receive(:decrypted_data).and_return("lksajdf")
        lambda { decryptor.for_decrypted_item }.should raise_error(Chef::EncryptedDataBagItem::DecryptionFailure)
      end
    end

    context "and the provided key is incorrect" do
      let(:decryption_key) { "wrong-passwd" }

      it "raises a sensible error" do
        lambda { decryptor.for_decrypted_item }.should raise_error(Chef::EncryptedDataBagItem::DecryptionFailure)
      end
    end

    context "and the cipher is not supported" do
      let(:encrypted_value) do
        ev = Chef::EncryptedDataBagItem::Encryptor.new(plaintext_data, encryption_key).for_encrypted_item
        ev["cipher"] = "aes-256-foo"
        ev
      end

      it "raises a sensible error" do
        lambda { decryptor.for_decrypted_item }.should raise_error(Chef::EncryptedDataBagItem::UnsupportedCipher)
      end
    end

    context "and version 2 format is required" do
      before do
        Chef::Config[:data_bag_decrypt_minimum_version] = 2
      end

      it "raises an error attempting to decrypt" do
        lambda { decryptor }.should raise_error(Chef::EncryptedDataBagItem::UnacceptableEncryptedDataBagItemFormat)
      end

    end

  end

  context "when decrypting a version 0 (YAML+aes-256-cbc+no iv) encrypted value" do
    let(:encrypted_value) do
      Version0Encryptor.encrypt_value(plaintext_data, encryption_key)
    end

    it "selects the correct strategy for version 0" do
      decryptor.should be_a_instance_of(Chef::EncryptedDataBagItem::Decryptor::Version0Decryptor)
    end

    it "decrypts the encrypted value" do
      decryptor.for_decrypted_item.should eq plaintext_data
    end

    context "and version 1 format is required" do
      before do
        Chef::Config[:data_bag_decrypt_minimum_version] = 1
      end

      it "raises an error attempting to decrypt" do
        lambda { decryptor }.should raise_error(Chef::EncryptedDataBagItem::UnacceptableEncryptedDataBagItemFormat)
      end

    end

  end
end

describe Chef::EncryptedDataBagItem do
  subject { described_class }
  let(:encrypted_data_bag_item) { subject.new(encoded_data, secret) }
  let(:plaintext_data) {{
      "id" => "item_name",
      "greeting" => "hello",
      "nested" => { "a1" => [1, 2, 3], "a2" => { "b1" => true }}
  }}
  let(:secret) { "abc123SECRET" }
  let(:encoded_data) { subject.encrypt_data_bag_item(plaintext_data, secret) }

  describe "encrypting" do

    it "doesn't encrypt the 'id' key" do
      encoded_data["id"].should eq "item_name"
    end

    it "encrypts non-collection objects" do
      encoded_data["greeting"]["version"].should eq 1
      encoded_data["greeting"].should have_key("iv")

      iv = encoded_data["greeting"]["iv"]
      encryptor = Chef::EncryptedDataBagItem::Encryptor.new("hello", secret, iv)

      encoded_data["greeting"]["encrypted_data"].should eq(encryptor.for_encrypted_item["encrypted_data"])
    end

    it "encrypts nested values" do
      encoded_data["nested"]["version"].should eq 1
      encoded_data["nested"].should have_key("iv")

      iv = encoded_data["nested"]["iv"]
      encryptor = Chef::EncryptedDataBagItem::Encryptor.new(plaintext_data["nested"], secret, iv)

      encoded_data["nested"]["encrypted_data"].should eq(encryptor.for_encrypted_item["encrypted_data"])
    end

  end

  describe "decrypting" do

    it "doesn't try to decrypt 'id'" do
      encrypted_data_bag_item["id"].should eq(plaintext_data["id"])
    end

    it "decrypts 'greeting'" do
      encrypted_data_bag_item["greeting"].should eq(plaintext_data["greeting"])
    end

    it "decrypts 'nested'" do
      encrypted_data_bag_item["nested"].should eq(plaintext_data["nested"])
    end

    it "decrypts everyting via to_hash" do
      encrypted_data_bag_item.to_hash.should eq(plaintext_data)
    end

    it "handles missing keys gracefully" do
      encrypted_data_bag_item["no-such-key"].should be_nil
    end
  end

  describe "loading" do
    it "should defer to Chef::DataBagItem.load" do
      Chef::DataBagItem.stub(:load).with(:the_bag, "my_codes").and_return(encoded_data)
      edbi = Chef::EncryptedDataBagItem.load(:the_bag, "my_codes", secret)
      edbi["greeting"].should eq(plaintext_data["greeting"])
    end
  end

  describe ".load_secret" do
    let(:secret) { "opensesame" }

    context "when /var/mysecret exists" do
      before do
        ::File.stub(:exist?).with("/var/mysecret").and_return(true)
        IO.stub(:read).with("/var/mysecret").and_return(secret)
      end

      it "load_secret('/var/mysecret') reads the secret" do
        Chef::EncryptedDataBagItem.load_secret("/var/mysecret").should eq secret
      end
    end

    context "when /etc/chef/encrypted_data_bag_secret exists" do
      before do
        path = Chef::Config.platform_specific_path("/etc/chef/encrypted_data_bag_secret")
        ::File.stub(:exist?).with(path).and_return(true)
        IO.stub(:read).with(path).and_return(secret)
      end

      it "load_secret(nil) reads the secret" do
        Chef::EncryptedDataBagItem.load_secret(nil).should eq secret
      end
    end

    context "when /etc/chef/encrypted_data_bag_secret does not exist" do
      before do
        path = Chef::Config.platform_specific_path("/etc/chef/encrypted_data_bag_secret")
        ::File.stub(:exist?).with(path).and_return(false)
      end

      it "load_secret(nil) emits a reasonable error message" do
        lambda { Chef::EncryptedDataBagItem.load_secret(nil) }.should raise_error(ArgumentError, /No secret specified and no secret found at #{Chef::Config[:encrypted_data_bag_secret]}/)
      end
    end

    context "path argument is a URL" do
      before do
        Kernel.stub(:open).with("http://www.opscode.com/").and_return(StringIO.new(secret))
      end

      it "reads from the URL" do
        Chef::EncryptedDataBagItem.load_secret("http://www.opscode.com/").should eq secret
      end
    end
  end
end
