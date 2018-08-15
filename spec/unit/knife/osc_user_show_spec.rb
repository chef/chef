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
# This code only remains to support users still  operating with
# Open Source Chef Server 11 and should be removed once support
# for OSC 11 ends. New development should occur user_show_spec.rb.

describe Chef::Knife::OscUserShow do
  before(:each) do
    Chef::Knife::OscUserShow.load_deps
    @knife = Chef::Knife::OscUserShow.new
    @knife.name_args = [ "my_user" ]
    @user_mock = double("user_mock")
  end

  it "loads and displays the user" do
    expect(Chef::User).to receive(:load).with("my_user").and_return(@user_mock)
    expect(@knife).to receive(:format_for_display).with(@user_mock)
    @knife.run
  end

  it "prints usage and exits when a user name is not provided" do
    @knife.name_args = []
    expect(@knife).to receive(:show_usage)
    expect(@knife.ui).to receive(:fatal)
    expect { @knife.run }.to raise_error(SystemExit)
  end
end
