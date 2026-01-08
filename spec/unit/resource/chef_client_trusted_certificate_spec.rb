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

describe Chef::Resource::ChefClientTrustedCertificate do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::ChefClientTrustedCertificate.new("foo", run_context) }
  let(:provider) { resource.provider_for_action(:add) }

  it "has a resource name of :chef_client_trusted_certificate" do
    expect(resource.resource_name).to eql(:chef_client_trusted_certificate)
  end

  it "has a name property of cert_name" do
    expect(resource.cert_name).to eql("foo")
  end

  it "sets the default action as :add" do
    expect(resource.action).to eql([:add])
  end

  it "supports :remove action" do
    expect { resource.action :remove }.not_to raise_error
  end

  describe "#cert_path" do
    it "appends .pem to new_resource.cert_name value" do
      resource.cert_name "something"
      expect(provider.cert_path).to match(%r{trusted_certs/something.pem$})
    end

    it "does not append .pem if cert_name already ends in .pem" do
      resource.cert_name "something.pem"
      expect(provider.cert_path).to match(%r{trusted_certs/something.pem$})
    end
  end

  describe "sensitive attribute" do
    context "should be insensitive by default" do
      it { expect(resource.sensitive).to(be_falsey) }
    end

    context "when set" do
      before { resource.sensitive(true) }

      it "should be set on the resource" do
        expect(resource.sensitive).to(be_truthy)
      end
    end
  end
end
