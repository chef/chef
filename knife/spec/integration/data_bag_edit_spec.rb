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
require "chef/knife/data_bag_edit"

describe "knife data bag edit", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  let(:out) { "Saved data_bag_item[box]\n" }
  let(:err) { "Saving data bag unencrypted. To encrypt it, provide an appropriate secret.\n" }
  let(:secret) { "abc" }
  let(:encrypt) { "Encrypted data bag detected, decrypting with provided secret.\n" }

  when_the_chef_server "is empty" do
    context "with encryption key" do
      it "fails to edit an item" do
        expect { knife("data bag edit bag box --secret #{secret}") }.to raise_error(Net::HTTPClientException)
      end
    end

    context "without encryption key" do
      it "fails to edit an item" do
        expect { knife("data bag edit bag box") }.to raise_error(Net::HTTPClientException)
      end
    end
  end

  when_the_chef_server "has some data bags" do
    before do
      data_bag "foo", {}
      data_bag "bag", { "box" => {} }
      data_bag "rocket", { "falcon9" => { heavy: "true" }, "atlas" => {}, "ariane" => {} }
      data_bag "encrypt", { "box" => { id: "box", foo: { "encrypted_data": "J8N0pJ+LFDQF3XvhzWgkSBOuZZn8Og==\n", "iv": "4S1sb4zLnMt71SXV\n", "auth_tag": "4ChINhxz4WmqOizvZNoPPg==\n", "version": 3, "cipher": "aes-256-gcm" } } }
    end

    context "with encryption key" do
      it "fails to edit a non-existing item" do
        expect { knife("data bag edit foo box --secret #{secret}") }.to raise_error(Net::HTTPClientException)
      end

      it "edits an encrypted data bag item" do
        pretty_json = Chef::JSONCompat.to_json_pretty({ id: "box", foo: "bar" })
        allow(Chef::JSONCompat).to receive(:to_json_pretty).and_return(pretty_json)
        knife("data bag edit encrypt box --secret #{secret}")
        knife("data bag show encrypt box --secret #{secret}").should_succeed stderr: encrypt, stdout: <<~EOM
          foo: bar
          id:  box
        EOM
      end

      it "encrypts an unencrypted data bag item" do
        knife("data bag edit rocket falcon9 --secret #{secret}")
        knife("data bag show rocket falcon9 --secret #{secret}").should_succeed stderr: encrypt, stdout: <<~EOM
          heavy: true
          id:    falcon9
        EOM
      end
    end

    context "without encryption key" do
      it "fails to edit a non-existing item" do
        expect { knife("data bag edit foo box") }.to raise_error(Net::HTTPClientException)
      end
      it "edits an empty data bag item" do
        pretty_json = Chef::JSONCompat.to_json_pretty({ id: "box", ab: "abc" })
        allow(Chef::JSONCompat).to receive(:to_json_pretty).and_return(pretty_json)
        knife("data bag edit bag box").should_succeed stderr: err, stdout: out
        knife("data bag show bag box").should_succeed <<~EOM
          ab: abc
          id: box
        EOM
      end
      it "edits a non-empty data bag item" do
        pretty_json = Chef::JSONCompat.to_json_pretty({ id: "falcon9", heavy: false })
        allow(Chef::JSONCompat).to receive(:to_json_pretty).and_return(pretty_json)
        knife("data bag edit rocket falcon9").should_succeed stderr: err, stdout: <<~EOM
          Saved data_bag_item[falcon9]
        EOM
        knife("data bag show rocket falcon9").should_succeed <<~EOM
          heavy: false
          id:    falcon9
        EOM
      end
    end
  end
end
