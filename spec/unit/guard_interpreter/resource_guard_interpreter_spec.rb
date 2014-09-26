#
# Author:: Adam Edwards (<adamed@getchef.com>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

describe Chef::GuardInterpreter::ResourceGuardInterpreter do
  let(:node) do
    node = Chef::Node.new

    node.default["kernel"] = Hash.new
    node.default["kernel"][:machine] = :x86_64.to_s
    node
  end

  let(:run_context) { Chef::RunContext.new(node, nil, nil) }

  let(:resource) do
    resource = Chef::Resource.new("powershell_unit_test", run_context)
    resource.stub(:run_action)
    resource.stub(:updated).and_return(true)
    resource
  end


  describe "get_interpreter_resource" do
    it "allows the guard interpreter to be set to Chef::Resource::Script" do
      resource.guard_interpreter(:script)
      expect { Chef::GuardInterpreter::ResourceGuardInterpreter.new(resource, "echo hi", nil) }.not_to raise_error
    end
    
    it "allows the guard interpreter to be set to Chef::Resource::PowershellScript derived indirectly from Chef::Resource::Script" do
      resource.guard_interpreter(:powershell_script)
      expect { Chef::GuardInterpreter::ResourceGuardInterpreter.new(resource, "echo hi", nil) }.not_to raise_error
    end
    
    it "raises an exception if guard_interpreter is set to a resource not derived from Chef::Resource::Script" do
      resource.guard_interpreter(:file)
      expect { Chef::GuardInterpreter::ResourceGuardInterpreter.new(resource, "echo hi", nil) }.to raise_error(ArgumentError)
    end
  end
end

