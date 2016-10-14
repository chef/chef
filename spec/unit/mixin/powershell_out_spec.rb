#
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

describe Chef::Mixin::PowershellOut, :windows_only do
  let(:shell_out_class) { Class.new { include Chef::Mixin::PowershellOut } }
  subject(:object) { shell_out_class.new }
  let(:architecture) { "something" }
  let(:flags) do
    "-NoLogo -NonInteractive -NoProfile -ExecutionPolicy Unrestricted -InputFormat None"
  end

  describe "#powershell_out" do
    it "runs a command and returns the shell_out object" do
      ret = double("Mixlib::ShellOut")
      expect(object).to receive(:shell_out).with(
        "powershell.exe #{flags} -Command \"Get-Process\"",
        {}
      ).and_return(ret)
      expect(object.powershell_out("Get-Process")).to eql(ret)
    end

    it "passes options" do
      ret = double("Mixlib::ShellOut")
      expect(object).to receive(:shell_out).with(
        "powershell.exe #{flags} -Command \"Get-Process\"",
        timeout: 600
      ).and_return(ret)
      expect(object.powershell_out("Get-Process", timeout: 600)).to eql(ret)
    end

    context "when double quote is passed in the powershell command" do
      it "passes if double quote is appended with single escape" do
        result = object.powershell_out("Write-Verbose \"Some String\" -Verbose")
        expect(result.stderr).to be == ""
        expect(result.stdout).to be == "VERBOSE: Some String\n"
      end

      it "suppresses error if double quote is passed with double escape characters" do
        expect { object.powershell_out("Write-Verbose \\\"Some String\\\" -Verbose") }.not_to raise_error
      end
    end
  end

  describe "#powershell_out!" do
    it "runs a command and returns the shell_out object" do
      mixlib_shellout = double("Mixlib::ShellOut")
      expect(object).to receive(:shell_out).with(
        "powershell.exe #{flags} -Command \"Get-Process\"",
        {}
      ).and_return(mixlib_shellout)
      expect(mixlib_shellout).to receive(:error!)
      expect(object.powershell_out!("Get-Process")).to eql(mixlib_shellout)
    end

    it "passes options" do
      mixlib_shellout = double("Mixlib::ShellOut")
      expect(object).to receive(:shell_out).with(
        "powershell.exe #{flags} -Command \"Get-Process\"",
        timeout: 600
      ).and_return(mixlib_shellout)
      expect(mixlib_shellout).to receive(:error!)
      expect(object.powershell_out!("Get-Process", timeout: 600)).to eql(mixlib_shellout)
    end

    context "when double quote is passed in the powershell command" do
      it "passes if double quote is appended with single escape" do
        result = object.powershell_out!("Write-Verbose \"Some String\" -Verbose")
        expect(result.stderr).to be == ""
        expect(result.stdout).to be == "VERBOSE: Some String\n"
      end

      it "raises error if double quote is passed with double escape characters" do
        expect { object.powershell_out!("Write-Verbose \\\"Some String\\\" -Verbose") }.to raise_error(Mixlib::ShellOut::ShellCommandFailed)
      end
    end
  end
end
