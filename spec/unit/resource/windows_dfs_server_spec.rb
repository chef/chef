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

describe Chef::Resource::WindowsDfsServer do
  let(:resource) { Chef::Resource::WindowsDfsServer.new("fakey_fakerton") }

  it "sets resource name as :windows_dfs_server" do
    expect(resource.resource_name).to eql(:windows_dfs_server)
  end

  it "sets the default action as :configure" do
    expect(resource.action).to eql([:configure])
  end

  it "supports :configure action" do
    expect { resource.action :configure }.not_to raise_error
  end
end
