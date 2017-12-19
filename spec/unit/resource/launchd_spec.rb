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

describe Chef::Resource::Launchd do
  let(:resource) { Chef::Resource::Launchd.new("io.chef.chef-client" ) }

  it "creates a new Chef::Resource::Launchd" do
    expect(resource).to be_a_kind_of(Chef::Resource)
    expect(resource).to be_a_kind_of(Chef::Resource::Launchd)
  end

  it "has a resource name of Launchd" do
    expect(resource.resource_name).to eql(:launchd)
  end

  it "has a default action of create" do
    expect(resource.action).to eql([:create])
  end

  it "accepts enable, disable, create, and delete as actions" do
    expect { resource.action :enable }.not_to raise_error
    expect { resource.action :disable }.not_to raise_error
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
  end
end
