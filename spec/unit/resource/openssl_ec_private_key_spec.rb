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

describe Chef::Resource::OpensslEcPrivateKey do

  let(:resource) { Chef::Resource::OpensslEcPrivateKey.new("fakey_fakerton") }

  it "has a resource name of :openssl_ec_private_key" do
    expect(resource.resource_name).to eql(:openssl_ec_private_key)
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

  it "has a default mode of '0600'" do
    expect(resource.mode).to eql("0600")
  end

  it "has a default key_cipher of 'des3'" do
    expect(resource.key_cipher).to eql("des3")
  end

  it "only accepts valid key_cipher values" do
    expect { resource.key_cipher "fako" }.to raise_error(ArgumentError)
  end

  it "has a default key_curve of 'prime256v1'" do
    expect(resource.key_curve).to eql("prime256v1")
  end

  it "only accepts valid key_curve values" do
    expect { resource.key_curve "fako" }.to raise_error(ArgumentError)
  end

  it "has a default force value of of false" do
    expect(resource.force).to eql(false)
  end

end
