#
# Author:: Tyler Ball (<tball@chef.io>)
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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
require "chef/encrypted_data_bag_item/check_encrypted"

class CheckEncryptedTester
  include Chef::EncryptedDataBagItem::CheckEncrypted
end

describe Chef::EncryptedDataBagItem::CheckEncrypted do

  let(:tester) { CheckEncryptedTester.new }

  it "detects the item is not encrypted when the data is empty" do
    expect(tester.encrypted?({})).to eq(false)
  end

  it "detects the item is not encrypted when the data only contains an id" do
    expect(tester.encrypted?({ id: "foo" })).to eq(false)
  end

  context "when the item is encrypted" do

    let(:default_secret) { "abc123SECRET" }
    let(:item_name) { "item_name" }
    let(:raw_data) do
      {
        "id" => item_name,
        "greeting" => "hello",
        "nested" => {
            "a1" => [1, 2, 3],
            "a2" => { "b1" => true },
        },
    } end

    let(:version) { 1 }
    let(:encoded_data) do
      Chef::Config[:data_bag_encrypt_version] = version
      Chef::EncryptedDataBagItem.encrypt_data_bag_item(raw_data, default_secret)
    end

    it "does not detect encryption when the item version is unknown" do
      # It shouldn't be possible for someone to normally encrypt an item with an unknown version - they would have to
      # do something funky like encrypting it and then manually changing the version
      modified_encoded_data = encoded_data
      modified_encoded_data["greeting"]["version"] = 4
      expect(tester.encrypted?(modified_encoded_data)).to eq(false)
    end

    shared_examples_for "encryption detected" do
      it "detects encrypted data bag" do
        expect( encryptor ).to receive(:encryptor_keys).at_least(:once).and_call_original
        expect(tester.encrypted?(encoded_data)).to eq(true)
      end
    end

    context "when encryption version is 1" do
      include_examples "encryption detected" do
        let(:version) { 1 }
        let(:encryptor) { Chef::EncryptedDataBagItem::Encryptor::Version1Encryptor }
      end
    end

    context "when encryption version is 2" do
      include_examples "encryption detected" do
        let(:version) { 2 }
        let(:encryptor) { Chef::EncryptedDataBagItem::Encryptor::Version2Encryptor }
      end
    end

    context "when encryption version is 3", :aes_256_gcm_only, ruby: "~> 2.0.0" do
      include_examples "encryption detected" do
        let(:version) { 3 }
        let(:encryptor) { Chef::EncryptedDataBagItem::Encryptor::Version3Encryptor }
      end
    end

  end

end
