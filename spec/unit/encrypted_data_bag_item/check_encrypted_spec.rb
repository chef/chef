#
# Author:: Tyler Ball (<tball@chef.io>)
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

    context "when the item version is unknown (perhaps a future version)" do
      let(:data) { { "id" => "test1", "foo" => { "encrypted_data" => "zNry4rkhV55Oltzf38eyHc/DF9a3tg==\n", "iv" => "vN3s6sSQZPKisnCr\n", "auth_tag" => "wDDEXbEMk802jrzKdRKXFQ==\n", "version" => 4, "cipher" => "aes-256-gcm" } } }

      it "detects the item is not encrypted" do
        expect(tester.encrypted?(data)).to eq(false)
      end
    end

    shared_examples_for "encryption detected" do
      it "detects encrypted data bag" do
        expect(tester.encrypted?(data)).to eq(true)
      end
    end

    context "when encryption version is 1" do
      let(:data) { { "id" => "test1", "foo" => { "encrypted_data" => "Vt21byoOCqjA3DGbQ/lc+xAB+Ku/56U1pD/D8jqALM4=\n", "iv" => "ZCOtnZide5/Su5DNBx+qRg==\n", "version" => 1, "cipher" => "aes-256-cbc" } } }
      include_examples "encryption detected"
    end

    context "when encryption version is 2" do
      let(:data) { { "id" => "test1", "foo" => { "encrypted_data" => "58mIocj2ab0qyhciEVy87Jot3KwPQuWNitWrOQjGm3U=\n", "hmac" => "g0SuXbzs2bKt/EARFawbd26n4XkDAiLjsxcQS/EMKT8=\n", "iv" => "ynzwVUWIKzTOi+TaDaVRrA==\n", "version" => 2, "cipher" => "aes-256-cbc" } } }
      include_examples "encryption detected"
    end

    context "when encryption version is 3" do
      let(:data) { { "id" => "test1", "foo" => { "encrypted_data" => "zNry4rkhV55Oltzf38eyHc/DF9a3tg==\n", "iv" => "vN3s6sSQZPKisnCr\n", "auth_tag" => "wDDEXbEMk802jrzKdRKXFQ==\n", "version" => 3, "cipher" => "aes-256-gcm" } } }
      include_examples "encryption detected"
    end
  end
end
