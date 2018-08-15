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

describe Chef::Knife::UserShow do
  let(:knife) { Chef::Knife::UserShow.new }
  let(:user_mock) { double("user_mock") }
  let(:stdout) { StringIO.new }

  before do
    Chef::Knife::UserShow.load_deps
    knife.name_args = [ "my_user" ]
    allow(user_mock).to receive(:username).and_return("my_user")
    allow(knife.ui).to receive(:stderr).and_return(stdout)
    allow(knife.ui).to receive(:stdout).and_return(stdout)
  end

  # delete this once OSC11 support is gone
  context "when the username field is not supported by the server" do
    before do
      allow(knife).to receive(:run_osc_11_user_show).and_raise(SystemExit)
      allow(Chef::UserV1).to receive(:load).with("my_user").and_return(user_mock)
      allow(user_mock).to receive(:username).and_return(nil)
    end

    it "displays the osc warning" do
      expect(knife.ui).to receive(:warn).with(knife.osc_11_warning)
      expect { knife.run }.to raise_error(SystemExit)
    end

    it "forwards the command to knife osc_user edit" do
      expect(knife).to receive(:run_osc_11_user_show)
      expect { knife.run }.to raise_error(SystemExit)
    end
  end

  it "loads and displays the user" do
    expect(Chef::UserV1).to receive(:load).with("my_user").and_return(user_mock)
    expect(knife).to receive(:format_for_display).with(user_mock)
    knife.run
  end

  it "prints usage and exits when a user name is not provided" do
    knife.name_args = []
    expect(knife).to receive(:show_usage)
    expect(knife.ui).to receive(:fatal)
    expect { knife.run }.to raise_error(SystemExit)
  end
end
