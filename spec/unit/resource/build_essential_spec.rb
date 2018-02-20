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

describe Chef::Resource::BuildEssential do

  let(:resource) { Chef::Resource::BuildEssential.new("foo") }

  it "has a resource name of :build_essential" do
    expect(resource.resource_name).to eql(:build_essential)
  end

  it "has a default action of install" do
    expect(resource.action).to eql([:install])
  end
end
