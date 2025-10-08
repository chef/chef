#
# Author:: Antony Thomas (<antonydeepak@gmail.com>)
# Copyright:: Copyright (c) Facebook, Inc. and its affiliates.
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

describe Chef::Resource::File::Verification::Json do
  let(:parent_resource) { Chef::Resource.new("llama") }

  before(:all) do
    @valid_json = "valid-#{Time.now.to_i}.json"
    f = File.new(@valid_json, "w")
    f.write('{
      "foo": "bar"
    }')
    f.close

    @invalid_json = "invalid-#{Time.now.to_i}.json"
    f = File.new(@invalid_json, "w")
    f.write("{
      'foo': 'bar'
    }")
    f.close

    @empty_json = "empty-#{Time.now.to_i}.json"
    File.new(@empty_json, "w").close
  end

  context "verify" do
    it "returns true for valid json" do
      v = Chef::Resource::File::Verification::Json.new(parent_resource, :json, {})
      expect(v.verify(@valid_json)).to eq(true)
    end

    it "returns false for invalid json" do
      v = Chef::Resource::File::Verification::Json.new(parent_resource, :json, {})
      expect(v.verify(@invalid_json)).to eq(false)
    end

    it "returns true for empty file" do
      # Expectation here is different from that of default JSON parser included in ruby 2.4+.
      # The default parser considers empty string as invalid JSON
      # https://stackoverflow.com/questions/30621802/why-does-json-parse-fail-with-the-empty-string,
      # however JSONCompat parses an empty string to `nil`.
      # We are retaining the behavior of JSONCompat for two reasons
      # - It is universal inside Chef codebase
      # - It can be helpful to not throw an error when a `file` or `template` is empty
      v = Chef::Resource::File::Verification::Json.new(parent_resource, :json, {})
      expect(v.verify(@empty_json)).to eq(true)
    end
  end

  after(:all) do
    File.delete(@valid_json)
    File.delete(@invalid_json)
    File.delete(@empty_json)
  end
end
