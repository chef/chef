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
# This code only remains to support users still	operating with
# Open Source Chef Server 11 and should be removed once support
# for OSC 11 ends. New development should occur in user_reregister_spec.rb.

describe Chef::Knife::OscUserReregister do
  before(:each) do
    Chef::Knife::OscUserReregister.load_deps
    @knife = Chef::Knife::OscUserReregister.new
    @knife.name_args = [ "a_user" ]
    @user_mock = double("user_mock", :private_key => "private_key")
    allow(Chef::User).to receive(:load).and_return(@user_mock)
    @stdout = StringIO.new
    allow(@knife.ui).to receive(:stdout).and_return(@stdout)
  end

  it "prints usage and exits when a user name is not provided" do
    @knife.name_args = []
    expect(@knife).to receive(:show_usage)
    expect(@knife.ui).to receive(:fatal)
    expect { @knife.run }.to raise_error(SystemExit)
  end

  it "reregisters the user and prints the key" do
    expect(@user_mock).to receive(:reregister).and_return(@user_mock)
    @knife.run
    expect(@stdout.string).to match( /private_key/ )
  end

  it "writes the private key to a file when --file is specified" do
    expect(@user_mock).to receive(:reregister).and_return(@user_mock)
    @knife.config[:file] = "/tmp/a_file"
    filehandle = StringIO.new
    expect(File).to receive(:open).with("/tmp/a_file", "w").and_yield(filehandle)
    @knife.run
    expect(filehandle.string).to eq("private_key")
  end
end
