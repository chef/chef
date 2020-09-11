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

describe Chef::Resource::WindowsUserPrivilege do
  let(:resource) { Chef::Resource::WindowsUserPrivilege.new("fakey_fakerton") }

  it "sets resource name as :windows_user_privilege" do
    expect(resource.resource_name).to eql(:windows_user_privilege)
  end

  it "sets the default action as :add" do
    expect(resource.action).to eql([:add])
  end
end
