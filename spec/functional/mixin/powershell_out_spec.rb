#
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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
require "chef/mixin/powershell_out"

describe Chef::Mixin::PowershellOut, windows_only: true do
  include Chef::Mixin::PowershellOut

  describe "#powershell_out" do
    it "runs a powershell command and collects stdout" do
      expect(powershell_out("get-process").run_command.stdout).to match /Handles\s+NPM\(K\)\s+PM\(K\)\s+WS\(K\)\s+VM\(M\)\s+CPU\(s\)\s+Id\s+/
    end

    it "does not raise exceptions when the command is invalid" do
      powershell_out("this-is-not-a-valid-command").run_command
    end
  end

  describe "#powershell_out!" do
    it "runs a powershell command and collects stdout" do
      expect(powershell_out!("get-process").run_command.stdout).to match /Handles\s+NPM\(K\)\s+PM\(K\)\s+WS\(K\)\s+VM\(M\)\s+CPU\(s\)\s+Id\s+/
    end

    it "raises exceptions when the command is invalid" do
      expect { powershell_out!("this-is-not-a-valid-command").run_command }.to raise_exception(Mixlib::ShellOut::ShellCommandFailed)
    end
  end
end
