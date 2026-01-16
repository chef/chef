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

describe Chef::Resource::OpensslX509Request do

  let(:resource) { Chef::Resource::OpensslX509Request.new("fakey_fakerton") }

  it "has a resource name of :openssl_x509_request" do
    expect(resource.resource_name).to eql(:openssl_x509_request)
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

  it "has a default key_type of 'ec'" do
    expect(resource.key_type).to eql("ec")
  end

  it "only accepts valid key_type values" do
    expect { resource.key_type "fako" }.to raise_error(ArgumentError)
  end

  it "has a default key_length of '2048'" do
    expect(resource.key_length).to eql(2048)
  end

  it "only accepts valid key_length values" do
    expect { resource.key_length 1023 }.to raise_error(ArgumentError)
  end

  it "has a default key_curve of 'prime256v1'" do
    expect(resource.key_curve).to eql("prime256v1")
  end

  it "only accepts valid key_curve values" do
    expect { resource.key_curve "fako" }.to raise_error(ArgumentError)
  end

  it "mode accepts both String and Integer values" do
    expect { resource.mode "644" }.not_to raise_error
    expect { resource.mode 644 }.not_to raise_error
  end
end
