#
# Author:: Adam Edwards (<adamed@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

describe Chef::Resource::WindowsScript::PowershellScript, :windows_only do

  include_context Chef::Resource::WindowsScript

  let (:architecture_command) { 'echo $env:PROCESSOR_ARCHITECTURE' }
  let (:output_command) { ' | out-file -encoding ASCII ' }

  it_behaves_like "a Windows script running on Windows"


  let(:successful_executable_script_content) { "#{ENV['SystemRoot']}\\system32\\attrib.exe $env:systemroot" }
  let(:failed_executable_script_content) { "#{ENV['SystemRoot']}\\system32\\attrib.exe /badargument" }
  let(:processor_architecture_script_content) { "echo $env:PROCESSOR_ARCHITECTURE" }
  let(:native_architecture_script_content) { "echo $env:PROCESSOR_ARCHITECTUREW6432" }
  let(:cmdlet_exit_code_not_found_content) { "get-item '.\\thisdoesnotexist'" }
  let(:cmdlet_exit_code_success_content) { "get-item ." }
  let(:windows_process_exit_code_success_content) { "#{ENV['SystemRoot']}\\system32\\attrib.exe $env:systemroot" }
  let(:windows_process_exit_code_not_found_content) { "findstr /notavalidswitch" }
  # Note that process exit codes on 32-bit Win2k3 cannot
  # exceed maximum value of signed integer
  let(:arbitrary_nonzero_process_exit_code) { 4193 }
  let(:arbitrary_nonzero_process_exit_code_content) { "exit #{arbitrary_nonzero_process_exit_code}" }
  let(:invalid_powershell_interpreter_flag) { "/thisflagisinvalid" }
  let(:valid_powershell_interpreter_flag) { "-Sta" }

  let!(:resource) do
    r = Chef::Resource::WindowsScript::PowershellScript.new("Powershell resource functional test", @run_context)
    r.code(successful_executable_script_content)
    r
  end

  describe "when the run action is invoked on Windows" do
    it "successfully executes a non-cmdlet Windows binary as the last command of the script" do
      resource.code(successful_executable_script_content + " | out-file -encoding ASCII #{script_output_path}")
      resource.returns(0)
      resource.run_action(:run)
    end

    it "returns the -27 for a powershell script that exits with -27", :windows_powershell_dsc_only do
      # This is broken on Powershell < 4.0
      file = Tempfile.new(['foo', '.ps1'])
      begin
        file.write "exit -27"
        file.close
        resource.code(". \"#{file.path}\"")
        resource.returns(-27)
        resource.run_action(:run)
      ensure
        file.close
        file.unlink
      end
    end


    it "returns the process exit code" do
      resource.code(arbitrary_nonzero_process_exit_code_content)
      resource.returns(arbitrary_nonzero_process_exit_code)
      resource.run_action(:run)
    end

    it "returns 0 if the last command was a cmdlet that succeeded" do
      resource.code(cmdlet_exit_code_success_content)
      resource.returns(0)
      resource.run_action(:run)
    end

    it "returns 0 if the last command was a cmdlet that succeeded and was preceded by a non-cmdlet Windows binary that failed" do
      resource.code([windows_process_exit_code_not_found_content, cmdlet_exit_code_success_content].join(';'))
      resource.returns(0)
      resource.run_action(:run)
    end

    it "returns 1 if the last command was a cmdlet that failed" do
      resource.code(cmdlet_exit_code_not_found_content)
      resource.returns(1)
      resource.run_action(:run)
    end

    it "returns 1 if the last command was a cmdlet that failed and was preceded by a successfully executed non-cmdlet Windows binary" do
      resource.code([windows_process_exit_code_success_content, cmdlet_exit_code_not_found_content].join(';'))
      resource.returns(1)
      resource.run_action(:run)
    end

    it "returns 1 if the script provided to the code attribute is not syntactically correct" do
      resource.code('if({)')
      resource.returns(1)
      resource.run_action(:run)
    end

    # This somewhat ambiguous case, two failures of different types,
    # seems to violate the principle of returning the status of the
    # last line executed -- in this case, we return the status of the
    # second to last line. This happens because Powershell gives no
    # way for us to determine whether the last operation was a cmdlet
    # or Windows process. Because the latter gives more specific
    # errors than 0 or 1, we return that instead, which is acceptable
    # since callers can test for nonzero rather than testing for 1.
    it "returns 1 if the last command was a cmdlet that failed and was preceded by an unsuccessfully executed non-cmdlet Windows binary" do
      resource.code([arbitrary_nonzero_process_exit_code_content,cmdlet_exit_code_not_found_content].join(';'))
      resource.returns(arbitrary_nonzero_process_exit_code)
      resource.run_action(:run)
    end

    it "returns 0 if the last command was a non-cmdlet Windows binary that succeeded and was preceded by a failed cmdlet" do
      resource.code([cmdlet_exit_code_success_content, arbitrary_nonzero_process_exit_code_content].join(';'))
      resource.returns(arbitrary_nonzero_process_exit_code)
      resource.run_action(:run)
    end

    it "returns a specific error code if the last command was a non-cmdlet Windows binary that failed and was preceded by cmdlet that succeeded" do
      resource.code([cmdlet_exit_code_success_content, arbitrary_nonzero_process_exit_code_content].join(';'))
      resource.returns(arbitrary_nonzero_process_exit_code)
      resource.run_action(:run)
    end

    it "returns a specific error code if the last command was a non-cmdlet Windows binary that failed and was preceded by cmdlet that failed" do
      resource.code([cmdlet_exit_code_not_found_content, arbitrary_nonzero_process_exit_code_content].join(';'))
      resource.returns(arbitrary_nonzero_process_exit_code)
      resource.run_action(:run)
    end

    it "returns 0 for $false as the last line of the script when convert_boolean_return is false" do
      resource.code "$false"
      resource.returns(0)
      resource.run_action(:run)
    end

    it "returns 0 for $true as the last line of the script when convert_boolean_return is false" do
      resource.code "$true"
      resource.returns(0)
      resource.run_action(:run)
    end

    it "returns 1 for $false as the last line of the script when convert_boolean_return is true" do
      resource.convert_boolean_return true
      resource.code "$false"
      resource.returns(1)
      resource.run_action(:run)
    end

    it "returns 0 for $true as the last line of the script when convert_boolean_return is true" do
      resource.convert_boolean_return true
      resource.code "$true"
      resource.returns(0)
      resource.run_action(:run)
    end

    it "executes a script with a 64-bit process on a 64-bit OS, otherwise a 32-bit process" do
      resource.code(processor_architecture_script_content + " | out-file -encoding ASCII #{script_output_path}")
      resource.returns(0)
      resource.run_action(:run)

      is_64_bit = (ENV['PROCESSOR_ARCHITECTURE'] == 'AMD64') || (ENV['PROCESSOR_ARCHITEW6432'] == 'AMD64')

      detected_64_bit = source_contains_case_insensitive_content?( get_script_output, 'AMD64' )

      expect(is_64_bit).to eq(detected_64_bit)
    end

    it "returns 1 if an invalid flag is passed to the interpreter" do
      resource.code(cmdlet_exit_code_success_content)
      resource.flags(invalid_powershell_interpreter_flag)
      resource.returns(1)
      resource.run_action(:run)
    end

    it "returns 0 if a valid flag is passed to the interpreter" do
      resource.code(cmdlet_exit_code_success_content)
      resource.flags(valid_powershell_interpreter_flag)
      resource.returns(0)
      resource.run_action(:run)
    end

    it "raises an error when given a block and a guard_interpreter" do
      resource.guard_interpreter :sh
      resource.only_if { true }
      expect { resource.should_skip?(:run) }.to raise_error(ArgumentError, /guard_interpreter does not support blocks/)
    end

  end

  context "when running on a 32-bit version of Windows", :windows32_only do

    it "executes a script with a 32-bit process if process architecture :i386 is specified" do
      resource.code(processor_architecture_script_content + " | out-file -encoding ASCII #{script_output_path}")
      resource.architecture(:i386)
      resource.returns(0)
      resource.run_action(:run)

      expect(source_contains_case_insensitive_content?( get_script_output, 'x86' )).to eq(true)
    end

    it "raises an exception if :x86_64 process architecture is specified" do
      begin
        expect(resource.architecture(:x86_64)).to raise_error Chef::Exceptions::Win32ArchitectureIncorrect
      rescue Chef::Exceptions::Win32ArchitectureIncorrect
      end
    end
  end

  context "when running on a 64-bit version of Windows", :windows64_only do
    it "executes a script with a 64-bit process if :x86_64 arch is specified" do
      resource.code(processor_architecture_script_content + " | out-file -encoding ASCII #{script_output_path}")
      resource.architecture(:x86_64)
      resource.returns(0)
      resource.run_action(:run)

      expect(source_contains_case_insensitive_content?( get_script_output, 'AMD64' )).to eq(true)
    end

    it "executes a script with a 32-bit process if :i386 arch is specified" do
      resource.code(processor_architecture_script_content + " | out-file -encoding ASCII #{script_output_path}")
      resource.architecture(:i386)
      resource.returns(0)
      resource.run_action(:run)

      expect(source_contains_case_insensitive_content?( get_script_output, 'x86' )).to eq(true)
    end
  end

  describe "when executing guards" do
    before(:each) do
      resource.not_if.clear
      resource.only_if.clear
    end

    context "when the guard_interpreter's default value of :powershell_script is overridden to :default" do
      before(:each) do
        resource.guard_interpreter :default
      end

      it "evaluates a succeeding not_if block using cmd.exe as false by default" do
        resource.not_if  "exit /b 0"
        expect(resource.should_skip?(:run)).to be_truthy
      end

      it "evaluates a failing not_if block using cmd.exe as true by default" do
        resource.not_if  "exit /b 2"
        expect(resource.should_skip?(:run)).to be_falsey
      end

      it "evaluates an succeeding only_if block using cmd.exe as true by default" do
        resource.only_if  "exit /b 0"
        expect(resource.should_skip?(:run)).to be_falsey
      end

      it "evaluates a failing only_if block using cmd.exe as false by default" do
        resource.only_if  "exit /b 2"
        expect(resource.should_skip?(:run)).to be_truthy
      end
    end

    context "the only_if is specified before the guard" do
      before do
        resource.guard_interpreter :default
      end

      it "evaluates a powershell $true for a only_if block as true" do
        resource.only_if "$true"
        resource.guard_interpreter :powershell_script
        expect(resource.should_skip?(:run)).to be_falsey
      end
    end

    context "with powershell_script as the guard_interpreter" do

      it "has a guard_interpreter attribute set to :powershell_script" do
        expect(resource.guard_interpreter).to eq(:powershell_script)
      end

      it "evaluates a powershell $false for a not_if block as true" do
        resource.not_if  "$false"
        expect(resource.should_skip?(:run)).to be_falsey
      end

      it "evaluates a powershell $true for a not_if block as false" do
        resource.not_if  "$true"
        expect(resource.should_skip?(:run)).to be_truthy
      end

      it "evaluates a powershell $false for an only_if block as false" do
        resource.only_if  "$false"
        expect(resource.should_skip?(:run)).to be_truthy
      end

      it "evaluates a powershell $true for a only_if block as true" do
        resource.only_if  "$true"
        expect(resource.should_skip?(:run)).to be_falsey
      end

      it "evaluates a not_if block using powershell.exe" do
        resource.not_if  "exit([int32](![System.Environment]::CommandLine.Contains('powershell.exe')))"
        expect(resource.should_skip?(:run)).to be_truthy
      end

      it "evaluates an only_if block using powershell.exe" do
        resource.only_if  "exit([int32](![System.Environment]::CommandLine.Contains('powershell.exe')))"
        expect(resource.should_skip?(:run)).to be_falsey
      end

      it "evaluates a non-zero powershell exit status for not_if as true" do
        resource.not_if  "exit 37"
        expect(resource.should_skip?(:run)).to be_falsey
      end

      it "evaluates a zero powershell exit status for not_if as false" do
        resource.not_if  "exit 0"
        expect(resource.should_skip?(:run)).to be_truthy
      end

      it "evaluates a failed executable exit status for not_if as false" do
        resource.not_if  windows_process_exit_code_not_found_content
        expect(resource.should_skip?(:run)).to be_falsey
      end

      it "evaluates a successful executable exit status for not_if as true" do
        resource.not_if  windows_process_exit_code_success_content
        expect(resource.should_skip?(:run)).to be_truthy
      end

      it "evaluates a failed executable exit status for only_if as false" do
        resource.only_if  windows_process_exit_code_not_found_content
        expect(resource.should_skip?(:run)).to be_truthy
      end

      it "evaluates a successful executable exit status for only_if as true" do
        resource.only_if  windows_process_exit_code_success_content
        expect(resource.should_skip?(:run)).to be_falsey
      end

      it "evaluates a failed cmdlet exit status for not_if as true" do
        resource.not_if  "throw 'up'"
        expect(resource.should_skip?(:run)).to be_falsey
      end

      it "evaluates a successful cmdlet exit status for not_if as true" do
        resource.not_if  "cd ."
        expect(resource.should_skip?(:run)).to be_truthy
      end

      it "evaluates a failed cmdlet exit status for only_if as false" do
        resource.only_if  "throw 'up'"
        expect(resource.should_skip?(:run)).to be_truthy
      end

      it "evaluates a successful cmdlet exit status for only_if as true" do
        resource.only_if  "cd ."
        expect(resource.should_skip?(:run)).to be_falsey
      end

      it "evaluates a not_if block using the cwd guard parameter" do
        custom_cwd = "#{ENV['SystemRoot']}\\system32\\drivers\\etc"
        resource.not_if  "exit ! [int32]($pwd.path -eq '#{custom_cwd}')", :cwd => custom_cwd
        expect(resource.should_skip?(:run)).to be_truthy
      end

      it "evaluates an only_if block using the cwd guard parameter" do
        custom_cwd = "#{ENV['SystemRoot']}\\system32\\drivers\\etc"
        resource.only_if  "exit ! [int32]($pwd.path -eq '#{custom_cwd}')", :cwd => custom_cwd
        expect(resource.should_skip?(:run)).to be_falsey
      end

      it "inherits cwd from the parent resource for only_if" do
        custom_cwd = "#{ENV['SystemRoot']}\\system32\\drivers\\etc"
        resource.cwd custom_cwd
        resource.only_if  "exit ! [int32]($pwd.path -eq '#{custom_cwd}')"
        expect(resource.should_skip?(:run)).to be_falsey
      end

      it "inherits cwd from the parent resource for not_if" do
        custom_cwd = "#{ENV['SystemRoot']}\\system32\\drivers\\etc"
        resource.cwd custom_cwd
        resource.not_if  "exit ! [int32]($pwd.path -eq '#{custom_cwd}')"
        expect(resource.should_skip?(:run)).to be_truthy
      end

      it "evaluates a 64-bit resource with a 64-bit guard and interprets boolean false as zero status code", :windows64_only do
        resource.architecture :x86_64
        resource.only_if  "exit [int32]($env:PROCESSOR_ARCHITECTURE -ne 'AMD64')"
        expect(resource.should_skip?(:run)).to be_falsey
      end

      it "evaluates a 64-bit resource with a 64-bit guard and interprets boolean true as nonzero status code", :windows64_only do
        resource.architecture :x86_64
        resource.only_if  "exit [int32]($env:PROCESSOR_ARCHITECTURE -eq 'AMD64')"
        expect(resource.should_skip?(:run)).to be_truthy
      end

      it "evaluates a 32-bit resource with a 32-bit guard and interprets boolean false as zero status code" do
        resource.architecture :i386
        resource.only_if  "exit [int32]($env:PROCESSOR_ARCHITECTURE -ne 'X86')"
        expect(resource.should_skip?(:run)).to be_falsey
      end

      it "evaluates a 32-bit resource with a 32-bit guard and interprets boolean true as nonzero status code" do
        resource.architecture :i386
        resource.only_if  "exit [int32]($env:PROCESSOR_ARCHITECTURE -eq 'X86')"
        expect(resource.should_skip?(:run)).to be_truthy
      end

      it "evaluates a simple boolean false as nonzero status code when convert_boolean_return is true for only_if" do
        resource.convert_boolean_return true
        resource.only_if  "$false"
        expect(resource.should_skip?(:run)).to be_truthy
      end

      it "evaluates a simple boolean false as nonzero status code when convert_boolean_return is true for not_if" do
        resource.convert_boolean_return true
        resource.not_if  "$false"
        expect(resource.should_skip?(:run)).to be_falsey
      end

      it "evaluates a simple boolean true as 0 status code when convert_boolean_return is true for only_if" do
        resource.convert_boolean_return true
        resource.only_if  "$true"
        expect(resource.should_skip?(:run)).to be_falsey
      end

      it "evaluates a simple boolean true as 0 status code when convert_boolean_return is true for not_if" do
        resource.convert_boolean_return true
        resource.not_if  "$true"
        expect(resource.should_skip?(:run)).to be_truthy
      end

      it "evaluates a 32-bit resource with a 32-bit guard and interprets boolean false as zero status code using convert_boolean_return for only_if" do
        resource.convert_boolean_return true
        resource.architecture :i386
        resource.only_if  "$env:PROCESSOR_ARCHITECTURE -eq 'X86'"
        expect(resource.should_skip?(:run)).to be_falsey
      end

      it "evaluates a 32-bit resource with a 32-bit guard and interprets boolean false as zero status code using convert_boolean_return for not_if" do
        resource.convert_boolean_return true
        resource.architecture :i386
        resource.not_if  "$env:PROCESSOR_ARCHITECTURE -ne 'X86'"
        expect(resource.should_skip?(:run)).to be_falsey
      end

      it "evaluates a 32-bit resource with a 32-bit guard and interprets boolean true as nonzero status code using convert_boolean_return for only_if" do
        resource.convert_boolean_return true
        resource.architecture :i386
        resource.only_if  "$env:PROCESSOR_ARCHITECTURE -ne 'X86'"
        expect(resource.should_skip?(:run)).to be_truthy
      end

      it "evaluates a 32-bit resource with a 32-bit guard and interprets boolean true as nonzero status code using convert_boolean_return for not_if" do
        resource.convert_boolean_return true
        resource.architecture :i386
        resource.not_if  "$env:PROCESSOR_ARCHITECTURE -eq 'X86'"
        expect(resource.should_skip?(:run)).to be_truthy
      end
    end
  end

  def get_script_output
    script_output = File.read(script_output_path)
  end

  def source_contains_case_insensitive_content?( source, content )
    source.downcase.include?(content.downcase)
  end
end
