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
require "chef/org"

describe Chef::Knife::OrgShow do

  let(:root_rest) { double("Chef::ServerAPI") }

  before :each do
    @knife = Chef::Knife::OrgShow.new
    @org_name = "foobar"
    @knife.name_args << @org_name
    @org = double("Chef::Org")
    expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_root]).and_return(root_rest)
    allow(@org).to receive(:root_rest).and_return(root_rest)
  end

  it "should load the organisation" do
    expect(root_rest).to receive(:get).with("organizations/#{@org_name}")
    @knife.run
  end

  it "should pretty print the output organisation" do
    expect(root_rest).to receive(:get).with("organizations/#{@org_name}")
    expect(@knife.ui).to receive(:output)
    @knife.run
  end
end
