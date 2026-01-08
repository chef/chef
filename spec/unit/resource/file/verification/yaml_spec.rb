#
# Author:: Antony Thomas (<antonydeepak@gmail.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Chef::Resource::File::Verification::Yaml do
  let(:parent_resource) { Chef::Resource.new("llama") }

  before(:all) do
    @valid_yaml = "valid-#{Time.now.to_i}.yaml"
    f = File.new(@valid_yaml, "w")
    f.write("# comment
        svc:
          mysqlPassword: sepppasswd
        ")
    f.close

    @invalid_yaml = "invalid-#{Time.now.to_i}.yaml"
    f = File.new(@invalid_yaml, "w")
    f.write("# comment
        svc:
          mysqlPassword: 'sepppasswd
        ")
    f.close

    @empty_yaml = "empty-#{Time.now.to_i}.yaml"
    File.new(@empty_yaml, "w").close
  end

  context "verify" do
    it "returns true for valid yaml" do
      v = Chef::Resource::File::Verification::Yaml.new(parent_resource, :yaml, {})
      expect(v.verify(@valid_yaml)).to eq(true)
    end

    it "returns false for invalid yaml" do
      v = Chef::Resource::File::Verification::Yaml.new(parent_resource, :yaml, {})
      expect(v.verify(@invalid_yaml)).to eq(false)
    end

    it "returns true for empty file" do
      v = Chef::Resource::File::Verification::Yaml.new(parent_resource, :yaml, {})
      expect(v.verify(@empty_yaml)).to eq(true)
    end
  end

  after(:all) do
    File.delete(@valid_yaml)
    File.delete(@invalid_yaml)
    File.delete(@empty_yaml)
  end
end
