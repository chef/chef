#
# Author:: Nolan Davidson (<nolan.davidson@gmail.com>)
# Copyright:: Copyright (c) Chef Software Inc.
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

describe Chef::Resource::Ksh do

  let(:resource) { Chef::Resource::Ksh.new("fakey_fakerton") }

  it "is a subclass of Chef::Resource::Script" do
    expect(resource).to be_a_kind_of(Chef::Resource::Script)
  end

  it "has a resource name of :ksh" do
    expect(resource.resource_name).to eql(:ksh)
  end

  it "sets the default action as :run" do
    expect(resource.action).to eql([:run])
  end

  it "supports :run action" do
    expect { resource.action :run }.not_to raise_error
  end

  it "has an interpreter of ksh" do
    expect(resource.interpreter).to eql("ksh")
  end

end
