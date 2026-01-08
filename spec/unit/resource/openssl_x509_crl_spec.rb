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

describe Chef::Resource::OpensslX509Crl do

  let(:resource) { Chef::Resource::OpensslX509Crl.new("fakey_fakerton") }

  it "has a resource name of :openssl_x509_crl" do
    expect(resource.resource_name).to eql(:openssl_x509_crl)
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

  it "has a default revocation_reason of 0" do
    expect(resource.revocation_reason).to eql(0)
  end

  it "has a default expiration of 8" do
    expect(resource.expire).to eql(8)
  end

  it "has a default renewal_threshold of 1" do
    expect(resource.renewal_threshold).to eql(1)
  end

  it "serial_to_revoke accepts both String and Integer values" do
    expect { resource.serial_to_revoke "123" }.not_to raise_error
    expect { resource.serial_to_revoke 123 }.not_to raise_error
  end

  it "mode accepts both String and Integer values" do
    expect { resource.mode "644" }.not_to raise_error
    expect { resource.mode 644 }.not_to raise_error
  end
end
