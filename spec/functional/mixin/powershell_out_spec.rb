#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
  include Chef::Mixin::PowershellOut

  it "requires PowerShell DLLs and runtimes to be present" do
    unless chef_powershell_gem_available?
      raise <<~ERROR

        ╔═══════════════════════════════════════════════════════════════════════════╗
        ║                          CRITICAL TEST FAILURE                            ║
        ╠═══════════════════════════════════════════════════════════════════════════╣
        ║                                                                           ║
        ║  PowerShell execution environment is NOT available!                       ║
        ║                                                                           ║
        ║  Required components missing:                                             ║
        ║    - chef-powershell gem and/or                                           ║
        ║    - Chef.PowerShell.dll and/or                                           ║
        ║    - vcruntime140.dll (Visual C++ Runtime)                                ║
        ║                                                                           ║
        ║  PowershellOut mixin tests CANNOT run without these dependencies.         ║
        ║                                                                           ║
        ║  Please ensure all required PowerShell runtime components are installed.  ║
        ║                                                                           ║
        ╚═══════════════════════════════════════════════════════════════════════════╝

      ERROR
    end
  end

  describe "#powershell_out" do
    it "runs a powershell command and collects stdout" do
      expect(powershell_out("get-process").run_command.stdout).to match(/Handles/)
    end

    it "uses :powershell by default" do
      expect(powershell_out("$PSVersionTable").run_command.stdout).to match(/CLRVersion/)
    end

    it ":pwsh interpreter uses core edition", :pwsh_installed do
      expect(powershell_out("$PSVersionTable", :pwsh).run_command.stdout).to match(/Core/)
    end

    it "does not raise exceptions when the command is invalid" do
      powershell_out("this-is-not-a-valid-command").run_command
    end
  end

  describe "#powershell_out!" do
    it "runs a powershell command and collects stdout" do
      expect(powershell_out!("get-process").run_command.stdout).to match(/Handles/)
    end

    it "raises exceptions when the command is invalid" do
      expect { powershell_out!("this-is-not-a-valid-command").run_command }.to raise_exception(Mixlib::ShellOut::ShellCommandFailed)
    end
  end
end
