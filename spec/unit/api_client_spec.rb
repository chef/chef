#
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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

require 'spec_helper'

require 'chef/api_client'

describe Chef::ApiClient do
  context "when Chef::ApiClient is called with an invalid version" do
    it "raises a Chef::Exceptions::InvalidObjectAPIVersionRequested" do
      expect{ Chef::ApiClient.new(-100) }.to raise_error(Chef::Exceptions::InvalidObjectAPIVersionRequested)
    end
  end

  context "when Chef::ApiClient is called with the default version" do
    it "properly creates the default Chef::ApiClient versioned object" do
      object = Chef::ApiClient.new
      expect(object.proxy_object.class).to eq(Chef::ApiClientV0)
    end
  end

  context "when Chef::ApiClient is called with a non-default version" do
    it "properly creates the correct Chef::ApiClient versioned object" do
      object = Chef::ApiClient.new(1)
      expect(object.proxy_object.class).to eq(Chef::ApiClientV1)
    end
  end

  context "when Chef::ApiClient is called with a non-default vasdfersion" do
    it "properly creates the correct Chef::ApiClient versionasdfed object" do
      object = Chef::ApiClient.new(1)
      expect(object.proxy_class).to eq(Chef::ApiClientV1)
    end
  end

end

