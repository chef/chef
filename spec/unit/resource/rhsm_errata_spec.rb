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

describe Chef::Resource::RhsmErrata do

  let(:resource) { Chef::Resource::RhsmErrata.new("fakey_fakerton") }

  it "has a resource name of :rhsm_errata" do
    expect(resource.resource_name).to eql(:rhsm_errata)
  end

  it "the errata_id property is the name_property" do
    expect(resource.errata_id).to eql("fakey_fakerton")
  end

  it "sets the default action as :install" do
    expect(resource.action).to eql([:install])
  end

  it "supports :install action" do
    expect { resource.action :install }.not_to raise_error
  end
end
