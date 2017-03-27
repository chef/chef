#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

describe Chef::Resource::Script do
  let(:resource_instance_name) { "fakey_fakerton" }
  let(:script_resource) { Chef::Resource::Script.new(resource_instance_name) }
  let(:resource_name) { :script }

  it "should accept a string for the interpreter" do
    script_resource.interpreter "naaaaNaNaNaaNaaNaaNaa"
    expect(script_resource.interpreter).to eql("naaaaNaNaNaaNaaNaaNaa")
  end

  context "when it has interpreter and flags" do
    before do
      script_resource.interpreter("gcc")
      script_resource.flags("-al")
    end

    it "returns the name as its identity" do
      expect(script_resource.identity).to eq(resource_instance_name)
    end
  end

  it_behaves_like "a script resource"
end
