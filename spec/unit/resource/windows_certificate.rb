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

describe Chef::Resource::WindowsCertificate do
  let(:resource) { Chef::Resource::WindowsCertificate.new("foobar") }

  it "sets resource name as :windows_certificate" do
    expect(resource.resource_name).to eql(:windows_certificate)
  end

  it "the source property is the name_property" do
    expect(resource.source).to eql("foobar")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create, :acl_add, :delete, and :verify actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :acl_add }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
    expect { resource.action :verify }.not_to raise_error
  end
end
