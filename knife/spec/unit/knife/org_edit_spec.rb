#
# Author:: Snehal Dwivedi (<sdwivedi@msystechnologies.com>)
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

require "knife_spec_helper"

describe Chef::Knife::OrgEdit do
  let(:knife) { Chef::Knife::OrgEdit.new }
  let(:root_rest) { double("Chef::ServerAPI") }

  before :each do
    Chef::Knife::OrgEdit.load_deps
    @org_name = "foobar"
    knife.name_args << @org_name
    @org = double("Chef::Org")
    knife.config[:disable_editing] = true
  end

  it "loads and edits the organisation" do
    expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_root]).and_return(root_rest)
    original_data = { "org_name" => "my_org" }
    data = { "org_name" => "my_org1" }
    expect(root_rest).to receive(:get).with("organizations/foobar").and_return(original_data)
    expect(knife).to receive(:edit_hash).with(original_data).and_return(data)
    expect(root_rest).to receive(:put).with("organizations/foobar", data)
    knife.run
  end

  it "prints usage and exits when a org name is not provided" do
    knife.name_args = []
    expect(knife).to receive(:show_usage)
    expect(knife.ui).to receive(:fatal)
    expect { knife.run }.to raise_error(SystemExit)
  end
end
