#
# Copyright:: Copyright 2015-2017, Chef Software, Inc.
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
require "chef/mixin/versioned_api"

describe Chef::Mixin::VersionedAPI do
  let(:dummy_class) { Class.new { extend Chef::Mixin::VersionedAPI } }

  it "allows a class to declare the minimum supported API version" do
    dummy_class.minimum_api_version 3
    expect(dummy_class.minimum_api_version).to eq(3)
  end
end

describe Chef::Mixin::VersionedAPIFactory do
  class V1Class; extend Chef::Mixin::VersionedAPI; minimum_api_version 1; end
  class V2Class; extend Chef::Mixin::VersionedAPI; minimum_api_version 2; end
  class V3Class; extend Chef::Mixin::VersionedAPI; minimum_api_version 3; end

  let(:factory_class) { Class.new { extend Chef::Mixin::VersionedAPIFactory } }

  before do
    Chef::ServerAPIVersions.instance.reset!
  end

  describe "#add_versioned_api_class" do
    it "adds a target class" do
      factory_class.add_versioned_api_class V1Class
      expect(factory_class.versioned_interfaces).to eq([V1Class])
    end

    it "can be called many times" do
      factory_class.add_versioned_api_class V1Class
      factory_class.add_versioned_api_class V2Class
      expect(factory_class.versioned_interfaces).to eq([V1Class, V2Class])
    end
  end

  describe "#versioned_api_class" do
    describe "with no known versions" do
      it "with one class it returns that class" do
        factory_class.add_versioned_api_class V2Class
        expect(factory_class.versioned_api_class.minimum_api_version).to eq(2)
      end

      it "with many classes it returns the highest minimum version" do
        factory_class.add_versioned_api_class V1Class
        factory_class.add_versioned_api_class V2Class
        factory_class.add_versioned_api_class V3Class
        expect(factory_class.versioned_api_class.minimum_api_version).to eq(3)
      end
    end

    describe "with a known version" do
      it "with one class it returns that class" do
        Chef::ServerAPIVersions.instance.set_versions({ "min_version" => 0, "max_version" => 2 })
        factory_class.add_versioned_api_class V2Class
        expect(factory_class.versioned_api_class.minimum_api_version).to eq(2)
      end

      it "with a maximum version it returns the highest possible versioned class" do
        Chef::ServerAPIVersions.instance.set_versions({ "min_version" => 0, "max_version" => 2 })
        factory_class.add_versioned_api_class V1Class
        factory_class.add_versioned_api_class V2Class
        factory_class.add_versioned_api_class V3Class
        expect(factory_class.versioned_api_class.minimum_api_version).to eq(2)
      end
    end

    it "with no classes it returns nil" do
      expect(factory_class.versioned_api_class).to be_nil
    end
  end

  describe "#best_request_version" do
    it "returns a String" do
      factory_class.add_versioned_api_class V2Class
      expect(factory_class.best_request_version).to be_a(String)
    end

    it "returns the most relevant version" do
      factory_class.add_versioned_api_class V2Class
      factory_class.add_versioned_api_class V3Class
      expect(factory_class.best_request_version).to eq("3")
    end
  end

  describe "#possible_requests" do
    it "returns the number of registered classes" do
      factory_class.add_versioned_api_class V2Class
      factory_class.add_versioned_api_class V3Class
      expect(factory_class.possible_requests).to eq(2)
    end
  end

  describe "#new" do
    it "creates an instance of the versioned class" do
      factory_class.add_versioned_api_class V2Class
      expect { factory_class.new }.to_not raise_error
      expect(factory_class.new.class).to eq(V2Class)
    end
  end

  describe "#def_versioned_delegator" do
    it "delegates the method to the correct class" do
      factory_class.add_versioned_api_class V2Class
      factory_class.def_versioned_delegator("test_method")
      expect(V2Class).to receive(:test_method).with("test message").and_return(true)

      factory_class.test_method("test message")
    end
  end
end
