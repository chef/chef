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

describe Chef::Knife::UserReregister do
  let(:knife) { Chef::Knife::UserReregister.new }
  let(:user_mock) { double("user_mock", private_key: "private_key") }
  let(:stdout) { StringIO.new }

  before do
    Chef::Knife::UserReregister.load_deps
    knife.name_args = [ "a_user" ]
    allow(Chef::UserV1).to receive(:load).and_return(user_mock)
    allow(knife.ui).to receive(:stdout).and_return(stdout)
    allow(knife.ui).to receive(:stderr).and_return(stdout)
    allow(user_mock).to receive(:username).and_return("a_user")
  end

  it "prints usage and exits when a user name is not provided" do
    knife.name_args = []
    expect(knife).to receive(:show_usage)
    expect(knife.ui).to receive(:fatal)
    expect { knife.run }.to raise_error(SystemExit)
  end

  it "reregisters the user and prints the key" do
    expect(user_mock).to receive(:reregister).and_return(user_mock)
    knife.run
    expect(stdout.string).to match( /private_key/ )
  end

  it "writes the private key to a file when --file is specified" do
    expect(user_mock).to receive(:reregister).and_return(user_mock)
    knife.config[:file] = "/tmp/a_file"
    filehandle = StringIO.new
    expect(File).to receive(:open).with("/tmp/a_file", "w").and_yield(filehandle)
    knife.run
    expect(filehandle.string).to eq("private_key")
  end
end
