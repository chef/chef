#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
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

describe Chef::Resource::HttpRequest do
  let(:resource) { Chef::Resource::HttpRequest.new("fakey_fakerton") }

  it "sets the default action as :get" do
    expect(resource.action).to eql([:get])
  end

  it "supports :delete, :get, :head, :options, :patch, :post, :put actions" do
    expect { resource.action :delete }.not_to raise_error
    expect { resource.action :get }.not_to raise_error
    expect { resource.action :head }.not_to raise_error
    expect { resource.action :options }.not_to raise_error
    expect { resource.action :patch }.not_to raise_error
    expect { resource.action :post }.not_to raise_error
    expect { resource.action :put }.not_to raise_error
  end

  it "sets url to a string" do
    resource.url "http://slashdot.org"
    expect(resource.url).to eql("http://slashdot.org")
  end

  it "sets the message to the name by default" do
    expect(resource.message).to eql("fakey_fakerton")
  end

  it "sets message to a string" do
    resource.message "monkeybars"
    expect(resource.message).to eql("monkeybars")
  end

  describe "when it has a message and headers" do
    before do
      resource.url("http://www.trololol.net")
      resource.message("Get sum post brah.")
      resource.headers({ "head" => "tail" })
    end

    it "returns the url as its identity" do
      expect(resource.identity).to eq("http://www.trololol.net")
    end
  end

end
