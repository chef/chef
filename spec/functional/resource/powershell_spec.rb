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

describe Chef::Resource::WindowsScript::Powershell, :windows_only do
  let(:script_content) { "whoami" }

  let!(:resource) do
    r = Chef::Resource::WindowsScript::Powershell.new("Powershell resource functional test", run_context)
    r.code(script_content)
    r
  end

  include_context Chef::Resource::WindowsScript    
  
  context "when the run action is invoked on Windows" do
    it "executes the script code" do
      resource.code(script_content + " > #{script_output_path}")
      resource.returns(0)
      resource.run_action(:run)
    end
  end  
end
