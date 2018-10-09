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

describe Chef::Resource::Timezone do
  let(:resource) { Chef::Resource::Timezone.new("fakey_fakerton") }

  it "sets resource name as :timezone" do
    expect(resource.resource_name).to eql(:timezone)
  end

  it "the timezone property is the name_property" do
    expect(resource.timezone).to eql("fakey_fakerton")
  end

  it "sets the default action as :set" do
    expect(resource.action).to eql([:set])
  end

  it "supports the :set action only" do
    expect { resource.action :set }.not_to raise_error
    expect { resource.action :unset }.to raise_error
  end
end
