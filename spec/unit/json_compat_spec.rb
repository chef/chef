#
# Author:: Juanje Ojeda (<juanje.ojeda@gmail.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require File.expand_path('../../spec_helper', __FILE__)
require 'chef/json_compat'

describe Chef::JSONCompat do

  describe "with JSON containing an existing class" do
    let(:json){'{"json_class": "Chef::Role"}'}
    it "returns an instance of the class instead of a Hash" do
      Chef::JSONCompat.from_json(json).class.should eq Chef::Role
    end
  end

  describe 'with JSON containing "Chef::Sandbox" as a json_class value' do
    require 'chef/sandbox' # Only needed for this test
    let(:json){'{"json_class": "Chef::Sandbox", "arbitrary": "data"}'}
    it "returns a Hash, because Chef::Sandbox is a dummy class" do
      Chef::JSONCompat.from_json(json).should eq({"json_class" => "Chef::Sandbox", "arbitrary" => "data"})
    end
  end

  describe "with a file with 300 or less nested entries" do
    before(:all) do
      @json = IO.read(File.join(CHEF_SPEC_DATA, 'big_json.json'))
      @hash = Chef::JSONCompat.from_json(@json)
    end

    describe "when a big json file is loaded" do
      it "should create a Hash from the file" do
        @hash.should be_kind_of(Hash)
      end
      it "should has 'test' as a 300th nested value" do
        @hash['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key'].should == 'test'
      end
    end
  end
  describe "with a file with more than 300 nested entries" do
    before(:all) do
      @json = IO.read(File.join(CHEF_SPEC_DATA, 'big_json_plus_one.json'))
      @hash = Chef::JSONCompat.from_json(@json, {:max_nesting => 301})
    end

    describe "when a big json file is loaded" do
      it "should create a Hash from the file" do
        @hash.should be_kind_of(Hash)
      end
      it "should has 'test' as a 301st nested value" do
        @hash['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key']['key'].should == 'test'
      end
    end
  end
end
