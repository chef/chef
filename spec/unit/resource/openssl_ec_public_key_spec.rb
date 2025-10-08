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
#

require "spec_helper"

describe Chef::Resource::OpensslEcPublicKey do

  let(:resource) { Chef::Resource::OpensslEcPublicKey.new("key") }

  it "has a resource name of :openssl_ec_public_key" do
    expect(resource.resource_name).to eql(:openssl_ec_public_key)
  end

  it "the path property is the name_property" do
    expect(resource.path).to eql("key")
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
end
