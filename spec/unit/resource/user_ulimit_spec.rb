#
# Author:: Tim Smith (<tsmith@chef.io>)
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
describe Chef::Resource::UserUlimit do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::UserUlimit.new("fakey_fakerton", run_context) }

  it "the username property is the name_property" do
    expect(resource.username).to eql("fakey_fakerton")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "coerces filename value to end in .conf" do
    resource.filename("foo")
    expect(resource.filename).to eql("foo.conf")
  end

  it "if username is * then the filename defaults to 00_all_limits.conf" do
    resource.username("*")
    expect(resource.filename).to eql("00_all_limits.conf")
  end

  it "if username is NOT * then the filename defaults to USERNAME_limits.conf" do
    expect(resource.filename).to eql("fakey_fakerton_limits.conf")
  end

  it "supports :create and :delete actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
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
