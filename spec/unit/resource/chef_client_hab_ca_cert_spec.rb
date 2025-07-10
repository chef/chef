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

describe Chef::Resource::ChefClientHabCaCert do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::ChefClientHabCaCert.new("foo", run_context) }
  let(:provider) { resource.provider_for_action(:add) }

  it "has a resource name of :chef_client_hab_ca_cert" do
    expect(resource.resource_name).to eql(:chef_client_hab_ca_cert)
  end

  it "has a name property of cert_name" do
    expect(resource.cert_name).to eql("foo")
  end

  it "sets the default action as :add" do
    expect(resource.action).to eql([:add])
  end

  it "does not support :remove action" do
    expect { resource.action :remove }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  describe "#cert_path" do
  end

end
