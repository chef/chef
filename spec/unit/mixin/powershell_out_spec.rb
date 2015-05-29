#
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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

require 'spec_helper'
require 'chef/mixin/powershell_out'

describe Chef::Mixin::PowershellOut do
  let(:shell_out_class) { Class.new { include Chef::Mixin::PowershellOut } }
  subject(:object) { shell_out_class.new }
  let(:architecture) { "something"  }
  let(:flags) {
     "-NoLogo -NonInteractive -NoProfile -ExecutionPolicy RemoteSigned -InputFormat None"
  }

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
  end
end
