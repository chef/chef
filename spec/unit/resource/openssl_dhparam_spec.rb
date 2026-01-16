#
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

describe Chef::Resource::OpensslDhparam do

  let(:resource) { Chef::Resource::OpensslDhparam.new("fakey_fakerton") }

  it "has a resource name of :openssl_dhparam" do
    expect(resource.resource_name).to eql(:openssl_dhparam)
  end

  it "the path property is the name_property" do
    expect(resource.path).to eql("fakey_fakerton")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create action" do
    expect { resource.action :create }.not_to raise_error
  end

  it "has a default mode of '0640'" do
    expect(resource.mode).to eql("0640")
  end

  it "has a default generator of 2" do
    expect(resource.generator).to eql(2)
  end

  it "has a default key_length of 2048" do
    expect(resource.key_length).to eql(2048)
  end

  it "only accepts valid key length" do
    expect { resource.key_length 1234 }.to raise_error(ArgumentError)
  end

  it "sets the mode which user provides for existing file" do
    resource.mode "0600"
    expect(resource.mode).to eql("0600")
  end

end
