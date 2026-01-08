#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Chef::Resource::WindowsShare do
  let(:resource) { Chef::Resource::WindowsShare.new("foobar") }

  it "sets resource name as :windows_share" do
    expect(resource.resource_name).to eql(:windows_share)
  end

  it "the share_name property is the name_property" do
    expect(resource.share_name).to eql("foobar")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create and :delete actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
  end

  it "coerces path to a single path separator format" do
    resource.path("C:/chef".freeze)
    expect(resource.path).to eql("C:\\chef")
    resource.path("C:\\chef")
    expect(resource.path).to eql("C:\\chef")
    resource.path("C:/chef".dup)
    expect(resource.path).to eql("C:\\chef")
  end
end
