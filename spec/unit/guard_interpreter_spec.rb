#
# Author:: Steven Danna (steve@chef.io)
# Copyright:: Copyright 2015-2016, Chef Software, Inc
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

describe Chef::GuardInterpreter do
  describe "#for_resource" do
    let (:resource) { Chef::Resource.new("foo") }

    it "returns a DefaultGuardInterpreter if the resource has guard_interpreter set to :default" do
      resource.guard_interpreter :default
      interpreter = Chef::GuardInterpreter.for_resource(resource, "", {})
      expect(interpreter.class).to eq(Chef::GuardInterpreter::DefaultGuardInterpreter)
    end

    it "returns a ResourceGuardInterpreter if the resource has guard_interpreter set to !:default" do
      resource.guard_interpreter :foobar
      # Mock the resource guard interpreter to avoid having to set up a lot of state
      # currently we are only testing that we get the correct class of object back
      rgi = double("Chef::GuardInterpreter::ResourceGuardInterpreter")
      allow(Chef::GuardInterpreter::ResourceGuardInterpreter).to receive(:new).and_return(rgi)
      interpreter = Chef::GuardInterpreter.for_resource(resource, "", {})
      expect(interpreter).to eq(rgi)
    end
  end
end
