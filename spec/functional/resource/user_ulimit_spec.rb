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

describe Chef::Resource::UserUlimit, :solaris_only do
  let(:username) { "chef_tm_functest_user" }

  let(:run_context) do
    Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
  end

  def ulimit_resource
    Chef::Resource::UserUlimit.new(username, run_context).tap do |r|
      r.filehandle_limit 8192
    end
  end

  after do
    # Best-effort cleanup of the Solaris project(4) entry this test creates,
    # regardless of whether the test itself succeeded.
    ulimit_resource.run_action(:delete)
  end

  it "creates a Solaris project(4) entry with the requested rctl and is idempotent" do
    resource = ulimit_resource
    resource.run_action(:create)
    expect(resource.solaris_project_exists?(resource.solaris_project_name)).to be true
    expect(
      resource.solaris_rctl_set?(resource.solaris_project_name, ["(basic,8192,deny)", "(privileged,8192,deny)"])
    ).to be true

    # running again with the same value should be a no-op
    resource2 = ulimit_resource
    resource2.run_action(:create)
    expect(resource2).not_to be_updated_by_last_action
  end

  it "removes the Solaris project(4) entry on :delete" do
    resource = ulimit_resource
    resource.run_action(:create)

    delete_resource = ulimit_resource
    delete_resource.run_action(:delete)
    expect(delete_resource.solaris_project_exists?(delete_resource.solaris_project_name)).to be false
  end

  it "raises for ulimit properties with no Solaris rctl equivalent" do
    resource = ulimit_resource
    resource.maxlogins_limit 5
    expect { resource.run_action(:create) }.to raise_error(Chef::Exceptions::UnsupportedAction, /maxlogins_limit/)
  end
end
