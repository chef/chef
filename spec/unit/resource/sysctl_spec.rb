#
# Copyright:: Copyright 2018, Chef Software, Inc.
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

describe Chef::Resource::Sysctl do
  let(:resource) { Chef::Resource::Sysctl.new("fakey_fakerton") }

  it "sets resource name as :sysctl" do
    expect(resource.resource_name).to eql(:sysctl)
  end

  it "the key property is the name_property" do
    expect(resource.key).to eql("fakey_fakerton")
  end

  it "sets the default action as :apply" do
    expect(resource.action).to eql([:apply])
  end

  it "supports :apply, :remove actions" do
    expect { resource.action :apply }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  it "coerces Arrays in the value property to space delimited Strings" do
    resource.value [1, 2, 3]
    expect(resource.value).to eql("1 2 3")
  end

  it "coerces Integers in the value property to Strings" do
    resource.value 1
    expect(resource.value).to eql("1")
  end

  it "coerces Floats in the value property to Strings" do
    resource.value 1.1
    expect(resource.value).to eql("1.1")
  end
end
