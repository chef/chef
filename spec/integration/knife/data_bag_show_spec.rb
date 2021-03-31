#
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

require "knife_spec_helper"
require "support/shared/integration/integration_helper"
require "support/shared/context/config"
require "chef/knife/data_bag_show"

describe "knife data bag show", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  when_the_chef_server "is empty" do
    it "raises error if try to retrieve it" do
      expect { knife("data bag show bag") }.to raise_error(Net::HTTPClientException)
    end
  end

  when_the_chef_server "contains data bags" do
    let(:right_secret) { "abc" }
    let(:wrong_secret) { "ab" }
    let(:err) { "Encrypted data bag detected, decrypting with provided secret.\n" }
    before do
      data_bag "x", {}
      data_bag "canteloupe", {}
      data_bag "rocket", { "falcon9" => { heavy: "true" }, "atlas" => {}, "ariane" => {} }
      data_bag "encrypt", { "box" => { id: "box", foo: { "encrypted_data": "J8N0pJ+LFDQF3XvhzWgkSBOuZZn8Og==\n", "iv": "4S1sb4zLnMt71SXV\n", "auth_tag": "4ChINhxz4WmqOizvZNoPPg==\n", "version": 3, "cipher": "aes-256-gcm" } } }
    end

    context "with encrypted data" do
      context "provided secret key" do
        it "shows data if secret key is correct" do
          knife("data bag show encrypt box --secret #{right_secret}").should_succeed stderr: err, stdout: <<~EOM
            foo: bar
            id:  box
          EOM
        end

        it "raises error if secret key is incorrect" do
          expect { knife("data bag show encrypt box --secret #{wrong_secret}") }.to raise_error(Chef::EncryptedDataBagItem::DecryptionFailure)
        end
      end

      context "not provided secret key" do
        it "shows encrypted data with a warning" do
          expect(knife("data bag show encrypt box").stderr).to eq("WARNING: Encrypted data bag detected, but no secret provided for decoding. Displaying encrypted data.\n")
        end
      end
    end

    context "with unencrypted data" do
      context "provided secret key" do
        it "shows unencrypted data with a warning" do
          expect(knife("data bag show rocket falcon9 --secret #{right_secret}").stderr).to eq("WARNING: Unencrypted data bag detected, ignoring any provided secret options.\n")
        end
      end

      context "not provided secret key" do
        it "shows null with an empty data bag" do
          knife("data bag show canteloupe").should_succeed "\n"
        end

        it "show list of items in a bag" do
          knife("data bag show rocket").should_succeed <<~EOM
            ariane
            atlas
            falcon9
          EOM
        end

        it "show data of the item" do
          knife("data bag show rocket falcon9").should_succeed <<~EOM
            heavy: true
            id:    falcon9
          EOM
        end
      end
    end
  end
end
