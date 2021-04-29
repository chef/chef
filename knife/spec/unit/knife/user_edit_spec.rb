#
# Author:: Steven Danna (<steve@chef.io>)
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

describe Chef::Knife::UserEdit do
  let(:knife) { Chef::Knife::UserEdit.new }
  let(:root_rest) { double("Chef::ServerAPI") }

  before(:each) do
    @stderr = StringIO.new
    @stdout = StringIO.new
    allow(knife.ui).to receive(:stderr).and_return(@stderr)
    allow(knife.ui).to receive(:stdout).and_return(@stdout)
    knife.name_args = [ "my_user2" ]
    knife.config[:disable_editing] = true
  end

  it "loads and edits the user" do
    data = { "username" => "my_user2" }
    edited_data = { "username" => "edit_user2" }
    result = {}
    @key = "You don't come into cooking to get rich - Ramsay"
    allow(result).to receive(:[]).with("private_key").and_return(@key)

    expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_root]).and_return(root_rest)
    expect(root_rest).to receive(:get).with("users/my_user2").and_return(data)
    expect(knife).to receive(:get_updated_user).with(data).and_return(edited_data)
    expect(root_rest).to receive(:put).with("users/my_user2", edited_data).and_return(result)
    knife.run
  end

  it "prints usage and exits when a user name is not provided" do
    knife.name_args = []
    expect(knife).to receive(:show_usage)
    expect(knife.ui).to receive(:fatal)
    expect { knife.run }.to raise_error(SystemExit)
  end
end
