#
# Author:: Steven Danna (<steve@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

# DEPRECATION NOTE
# This code only remains to support users still operating with
# Open Source Chef Server 11 and should be removed once support
# for OSC 11 ends. New development should occur in user_edit_spec.rb.

describe Chef::Knife::OscUserEdit do
  before(:each) do
    @stderr = StringIO.new
    @stdout = StringIO.new

    Chef::Knife::OscUserEdit.load_deps
    @knife = Chef::Knife::OscUserEdit.new
    allow(@knife.ui).to receive(:stderr).and_return(@stderr)
    allow(@knife.ui).to receive(:stdout).and_return(@stdout)
    @knife.name_args = [ "my_user" ]
    @knife.config[:disable_editing] = true
  end

  it "loads and edits the user" do
    data = { :name => "my_user" }
    allow(Chef::User).to receive(:load).with("my_user").and_return(data)
    expect(@knife).to receive(:edit_hash).with(data).and_return(data)
    @knife.run
  end

  it "prints usage and exits when a user name is not provided" do
    @knife.name_args = []
    expect(@knife).to receive(:show_usage)
    expect(@knife.ui).to receive(:fatal)
    expect { @knife.run }.to raise_error(SystemExit)
  end
end
