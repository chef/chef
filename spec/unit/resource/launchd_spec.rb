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
  let(:resource) { Chef::Resource::Launchd.new("fakey_fakerton" ) }

  it "has a resource name of Launchd" do
    expect(resource.resource_name).to eql(:launchd)
  end

  it "the label property is the name_property" do
    expect(resource.label).to eql("fakey_fakerton")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create, :create_if_missing, :delete, :disable, :enable, :restart actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :create_if_missing }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
    expect { resource.action :disable }.not_to raise_error
    expect { resource.action :enable }.not_to raise_error
    expect { resource.action :restart }.not_to raise_error
  end
end
