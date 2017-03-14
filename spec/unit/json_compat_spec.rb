#
# Author:: Juanje Ojeda (<juanje.ojeda@gmail.com>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

require File.expand_path("../../spec_helper", __FILE__)
require "chef/json_compat"

describe Chef::JSONCompat do
  before { Chef::Config[:treat_deprecation_warnings_as_errors] = false }

  describe "#parse with JSON containing comments" do
    let(:json) { %Q{{\n/* comment */\n// comment 2\n"json_class": "Chef::Role"}} }

    it "returns a Hash" do
      expect(Chef::JSONCompat.parse(json).class).to eq Hash
    end
  end

  describe "when pretty printing an object that defines #to_json" do
    class Foo
      def to_json(*a)
        Chef::JSONCompat.to_json({ "foo" => 1234, "bar" => { "baz" => 5678 } }, *a)
      end
    end

    it "should work" do
      f = Foo.new
      expect(Chef::JSONCompat.to_json_pretty(f)).to eql("{\n  \"foo\": 1234,\n  \"bar\": {\n    \"baz\": 5678\n  }\n}\n")
    end

    include_examples "to_json equivalent to Chef::JSONCompat.to_json" do
      let(:jsonable) { Foo.new }
    end
  end

  describe "with the file with 252 or less nested entries" do
    let(:json) { IO.read(File.join(CHEF_SPEC_DATA, "nested.json")) }
    let(:hash) { Chef::JSONCompat.from_json(json) }

    describe "when the 252 json file is loaded" do
      it "should create a Hash from the file" do
        expect(hash).to be_kind_of(Hash)
      end

      it "should has 'test' as a 252 nested value" do
        v = 252.times.inject(hash) do |memo, _|
          memo["key"]
        end
        expect(v).to eq("test")
      end
    end
  end

  it "should define .to_json on all classes" do
    class SomeClass; end

    expect(SomeClass.new.respond_to?(:to_json)).to eq(true)
  end
end
