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

describe Chef::Resource::RhsmErrataLevel do

  let(:resource) { Chef::Resource::RhsmErrataLevel.new("moderate") }

  it "has a resource name of :rhsm_errata_level" do
    expect(resource.resource_name).to eql(:rhsm_errata_level)
  end

  it "the errata_level property is the name_property" do
    expect(resource.errata_level).to eql("moderate")
  end

  it "sets the default action as :install" do
    expect(resource.action).to eql([:install])
  end

  it "supports :install action" do
    expect { resource.action :install }.not_to raise_error
  end

  it "coerces the errata_level to be lowercase" do
    resource.errata_level "Important"
    expect(resource.errata_level).to eql("important")
  end

  it "raises an exception if invalid errata_level is passed" do
    expect do
      resource.errata_level "FOO"
    end.to raise_error(Chef::Exceptions::ValidationFailed)
  end
end
