#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2014-2016, Lamont Granquist
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

describe Chef::Knife::RoleShow do
  let(:role) { "base" }

  let(:knife) do
    knife = Chef::Knife::RoleShow.new
    knife.name_args = [ role ]
    knife
  end

  let(:role_mock) { double("role_mock") }

  describe "run" do
    it "should list the role" do
      expect(Chef::Role).to receive(:load).with("base").and_return(role_mock)
      expect(knife).to receive(:format_for_display).with(role_mock)
      knife.run
    end

    it "should pretty print json" do
      knife.config[:format] = "json"
      stdout = StringIO.new
      allow(knife.ui).to receive(:stdout).and_return(stdout)
      fake_role_contents = { "foo" => "bar", "baz" => "qux" }
      expect(Chef::Role).to receive(:load).with("base").and_return(fake_role_contents)
      knife.run
      expect(stdout.string).to eql("{\n  \"foo\": \"bar\",\n  \"baz\": \"qux\"\n}\n")
    end

    context "without a role name" do
      let(:role) {}

      it "should print usage and exit when a role name is not provided" do
        expect(knife).to receive(:show_usage)
        expect(knife.ui).to receive(:fatal)
        expect { knife.run }.to raise_error(SystemExit)
      end
    end
  end
end
