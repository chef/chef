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
  let(:successful_executable_script_content) { "#{ENV['SystemRoot']}\\system32\\attrib.exe" }
  let(:failed_executable_script_content) { "#{ENV['SystemRoot']}\\system32\\attrib.exe /badargument" }
  let(:processor_architecture_script_content) { "echo $env:PROCESSOR_ARCHITECTURE" }
  let(:native_architecture_script_content) { "echo $env:PROCESSOR_ARCHITECTUREW6432" }  
  let!(:resource) do
    r = Chef::Resource::WindowsScript::PowershellScript.new("Powershell resource functional test", run_context)
    r.code(successful_executable_script_content)
    r
  end

  before(:each) do
    resource.architecture nil
  end
  

  include_context Chef::Resource::WindowsScript    
  
  context "when the run action is invoked on Windows" do
    it "executes the script code" do
      resource.code(successful_executable_script_content + " > #{script_output_path}")
      resource.returns(0)
      resource.run_action(:run)
    end

    it "executes a script with a 64-bit process on a 64-bit OS, otherwise a 32-bit process" do
      resource.code(native_architecture_script_content + " > #{script_output_path}")
      resource.returns(0)
      resource.run_action(:run)

      source_contains_case_insensitive_content?( get_script_output, ENV['PROCESSOR_ARCHITECTURE'] )
    end
  end

  context "when running on a 32-bit version of Windows", :windows32_only do

    it "executes a script with a 32-bit process if process architecture :i386 is specified" do
      resource.code(native_architecture_script_content + " > #{script_output_path}")
      resource.architecture(:i386)
      resource.returns(0)
      resource.run_action(:run)

      source_contains_case_insensitive_content?( get_script_output, 'x86' )
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
      resource.code(native_architecture_script_content + " > #{script_output_path}")
      resource.architecture(:x86_64)
      resource.returns(0)
      resource.run_action(:run)

      source_contains_case_insensitive_content?( get_script_output, 'x64' )
    end
    
    it "executes a script with a 32-bit process if :i386 arch is specified" do
      resource.code(native_architecture_script_content + " > #{script_output_path}")
      resource.architecture(:i386)
      resource.returns(0)
      resource.run_action(:run)

      source_contains_case_insensitive_content?( get_script_output, 'x86' )
    end
  end
  

  def get_script_output
    script_output = nil
    
    ::File.open(script_output_path) do | output_file |
      script_output = output_file.read
      output_file.close
    end

    script_output
  end

  def source_contains_case_insensitive_content?( source, content )
    source.downcase.include?(content.downcase)
  end
end
