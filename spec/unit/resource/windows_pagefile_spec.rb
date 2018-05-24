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

describe Chef::Resource::WindowsPagefile do
  let(:resource) { Chef::Resource::WindowsPagefile.new("C:\\pagefile.sys") }

  it "sets resource name as :windows_pagefile" do
    expect(resource.resource_name).to eql(:windows_pagefile)
  end

  it "the path property is the name_property" do
    expect(resource.path).to eql("C:\\pagefile.sys")
  end

  it "sets the default action as :set" do
    expect(resource.action).to eql([:set])
  end

  it "supports :delete, :set actions" do
    expect { resource.action :delete }.not_to raise_error
    expect { resource.action :set }.not_to raise_error
  end

  it "coerces forward slashes in the path property to back slashes" do
    resource.path "C:/pagefile.sys"
    expect(resource.path).to eql("C:\\pagefile.sys")
  end

  it "automatic_managed property defaults to false" do
    expect(resource.automatic_managed).to eql(false)
  end

end
