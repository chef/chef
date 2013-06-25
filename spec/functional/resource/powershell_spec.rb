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
require 'functional/resource/batch_spec.rb'

describe Chef::Resource::WindowsScript::PowershellScript, :windows_only do

  include_context Chef::Resource::WindowsScript      

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

    # This somewhat ambiguous case, two failures of different types,
    # seems to violate the principle of returning the status of the
    # last line executed -- in this case, we return the status of the
    # second to last line. This happens because Powershell gives no
    # way for us to determine whether the last operation was a cmdlet
    # or Windows process. Because the latter gives more specified
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
    
    it "executes a script with a 64-bit process on a 64-bit OS, otherwise a 32-bit process" do
      resource.code(processor_architecture_script_content + " | out-file -encoding ASCII #{script_output_path}")
      resource.returns(0)
      resource.run_action(:run)

      is_64_bit = (ENV['PROCESSOR_ARCHITECTURE'] == 'AMD64') || (ENV['PROCESSOR_ARCHITEW6432'] == 'AMD64')
      
      detected_64_bit = source_contains_case_insensitive_content?( get_script_output, 'AMD64' )

      is_64_bit.should == detected_64_bit
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
  end

  context "when running on a 32-bit version of Windows", :windows32_only do

    it "executes a script with a 32-bit process if process architecture :i386 is specified" do
      resource.code(processor_architecture_script_content + " | out-file -encoding ASCII #{script_output_path}")
      resource.architecture(:i386)
      resource.returns(0)
      resource.run_action(:run)

      source_contains_case_insensitive_content?( get_script_output, 'x86' ).should == true
    end

    it "raises an exception if :x86_64 process architecture is specified" do
      begin
        resource.architecture(:x86_64).should raise_error Chef::Exceptions::Win32ArchitectureIncorrect
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

      source_contains_case_insensitive_content?( get_script_output, 'AMD64' ).should == true
    end
    
    it "executes a script with a 32-bit process if :i386 arch is specified" do
      resource.code(processor_architecture_script_content + " | out-file -encoding ASCII #{script_output_path}")
      resource.architecture(:i386)
      resource.returns(0)
      resource.run_action(:run)

      source_contains_case_insensitive_content?( get_script_output, 'x86' ).should == true
    end
  end

  def get_script_output
    script_output = File.read(script_output_path)
  end

  def source_contains_case_insensitive_content?( source, content )
    source.downcase.include?(content.downcase)
  end
end
