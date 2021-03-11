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
require "chef/knife/data_bag_create"

describe "knife data bag create", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  let(:err) { "Created data_bag[foo]\n" }
  let(:out) { "Created data_bag_item[bar]\n" }
  let(:exists) { "Data bag foo already exists\n" }
  let(:secret) { "abc" }

  when_the_chef_server "is empty" do
    context "with encryption key" do
      it "creates a new data bag and item" do
        pretty_json = Chef::JSONCompat.to_json_pretty({ id: "bar", test: "pass" })
        allow(Chef::JSONCompat).to receive(:to_json_pretty).and_return(pretty_json)
        knife("data bag create foo bar --secret #{secret}").should_succeed stdout: out, stderr: err
        expect(knife("data bag show foo bar --secret #{secret}").stderr).to eq("Encrypted data bag detected, decrypting with provided secret.\n")
        expect(knife("data bag show foo bar --secret #{secret}").stdout).to eq("id:   bar\ntest: pass\n")
      end

      it "creates a new data bag and an empty item" do
        knife("data bag create foo bar --secret #{secret}").should_succeed stdout: out, stderr: err
        expect(knife("data bag show foo bar --secret #{secret}").stderr).to eq("WARNING: Unencrypted data bag detected, ignoring any provided secret options.\n")
        expect(knife("data bag show foo bar --secret #{secret}").stdout).to eq("id: bar\n")
      end
    end

    context "without encryption key" do
      it "creates a new data bag" do
        knife("data bag create foo").should_succeed stderr: err
        expect(knife("data bag show foo").stderr).to eq("")
      end

      it "creates a new data bag and item" do
        knife("data bag create foo bar").should_succeed stdout: out, stderr: err
        expect(knife("data bag show foo").stdout).to eq("bar\n")
      end
    end
  end

  when_the_chef_server "has some data bags" do
    before do
      data_bag "foo", {}
      data_bag "bag", { "box" => {} }
    end

    context "with encryption key" do
      it "creates a new data bag and item" do
        pretty_json = Chef::JSONCompat.to_json_pretty({ id: "bar", test: "pass" })
        allow(Chef::JSONCompat).to receive(:to_json_pretty).and_return(pretty_json)
        knife("data bag create rocket bar --secret #{secret}").should_succeed stdout: out, stderr: <<~EOM
          Created data_bag[rocket]
        EOM
        expect(knife("data bag show rocket bar --secret #{secret}").stderr).to eq("Encrypted data bag detected, decrypting with provided secret.\n")
        expect(knife("data bag show rocket bar --secret #{secret}").stdout).to eq("id:   bar\ntest: pass\n")
      end

      it "creates a new data bag and an empty item" do
        knife("data bag create rocket bar --secret #{secret}").should_succeed stdout: out, stderr: <<~EOM
          Created data_bag[rocket]
        EOM
        expect(knife("data bag show rocket bar --secret #{secret}").stderr).to eq("WARNING: Unencrypted data bag detected, ignoring any provided secret options.\n")
        expect(knife("data bag show rocket bar --secret #{secret}").stdout).to eq("id: bar\n")
      end

      it "adds a new item to an existing bag" do
        knife("data bag create foo bar --secret #{secret}").should_succeed stdout: out, stderr: exists
        expect(knife("data bag show foo bar --secret #{secret}").stderr).to eq("WARNING: Unencrypted data bag detected, ignoring any provided secret options.\n")
        expect(knife("data bag show foo bar --secret #{secret}").stdout).to eq("id: bar\n")
      end

      it "fails to add an existing item" do
        expect { knife("data bag create bag box --secret #{secret}") }.to raise_error(Net::HTTPClientException)
      end
    end

    context "without encryption key" do
      it "creates a new data bag" do
        knife("data bag create rocket").should_succeed stderr: <<~EOM
          Created data_bag[rocket]
        EOM
      end

      it "creates a new data bag and item" do
        knife("data bag create rocket bar").should_succeed stdout: out, stderr: <<~EOM
          Created data_bag[rocket]
        EOM
      end

      it "adds a new item to an existing bag" do
        knife("data bag create foo bar").should_succeed stdout: out, stderr: exists
      end

      it "refuses to create an existing data bag" do
        knife("data bag create foo").should_succeed stderr: exists
      end

      it "fails to add an existing item" do
        expect { knife("data bag create bag box") }.to raise_error(Net::HTTPClientException)
      end
    end
  end
end
