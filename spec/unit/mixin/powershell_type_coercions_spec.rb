#
# Author:: Jay Mundrawala (<jdm@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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
require "chef/mixin/powershell_type_coercions"
require "base64"

class Chef::PSTypeTester
  include Chef::Mixin::PowershellTypeCoercions
end

describe Chef::Mixin::PowershellTypeCoercions do
  let (:test_class) { Chef::PSTypeTester.new }

  describe "#translate_type" do
    it "single quotes a string" do
      expect(test_class.translate_type("foo")).to eq("'foo'")
    end

    ["'", '"', "#", "`"].each do |c|
      it "base64 encodes a string that contains #{c}" do
        expect(test_class.translate_type("#{c}")).to match(Base64.strict_encode64(c))
      end
    end

    it "does not quote an integer" do
      expect(test_class.translate_type(123)).to eq("123")
    end

    it "does not quote a floating point number" do
      expect(test_class.translate_type(123.4)).to eq("123.4")
    end

    it "translates $false when an instance of FalseClass is provided" do
      expect(test_class.translate_type(false)).to eq("$false")
    end

    it "translates $true when an instance of TrueClass is provided" do
      expect(test_class.translate_type(true)).to eq("$true")
    end

    it "translates all members of a hash and wrap them in @{} separated by ;" do
      expect(test_class.translate_type({ "a" => 1, "b" => 1.2, "c" => false, "d" => true
      })).to eq("@{a=1;b=1.2;c=$false;d=$true}")
    end

    it "translates all members of an array and them by a ," do
      expect(test_class.translate_type([true, false])).to eq("@($true,$false)")
    end

    it "translates a Chef::Node::ImmutableMash like a hash" do
      test_mash = Chef::Node::ImmutableMash.new({ "a" => 1, "b" => 1.2,
                                                  "c" => false, "d" => true })
      expect(test_class.translate_type(test_mash)).to eq("@{a=1;b=1.2;c=$false;d=$true}")
    end

    it "translates a Chef::Node::ImmutableArray like an array" do
      test_array = Chef::Node::ImmutableArray.new([true, false])
      expect(test_class.translate_type(test_array)).to eq("@($true,$false)")
    end

    it "falls back :to_psobject if we have not defined at explicit rule" do
      ps_obj = double("PSObject")
      expect(ps_obj).to receive(:to_psobject).and_return("$true")
      expect(test_class.translate_type(ps_obj)).to eq("($true)")
    end
  end
end
