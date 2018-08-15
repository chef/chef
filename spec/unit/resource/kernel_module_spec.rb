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

describe Chef::Resource::KernelModule do
  let(:resource) { Chef::Resource::KernelModule.new("foo") }

  it "sets resource name as :kernel_module" do
    expect(resource.resource_name).to eql(:kernel_module)
  end

  it "is not a preview resource in Chef 15" do
    pending("Chef 15") unless Chef::VERSION.start_with?("15")
    expect(resource.class.preview_resource).to be_falsey
  end

  it "sets the default action as :install" do
    expect(resource.action).to eql([:install])
  end

  it "sets the modname property as its name property" do
    expect(resource.modname).to eql("foo")
  end

  it "supports :create and :flush actions" do
    expect { resource.action :install }.not_to raise_error
    expect { resource.action :uninstall }.not_to raise_error
    expect { resource.action :blacklist }.not_to raise_error
    expect { resource.action :load }.not_to raise_error
    expect { resource.action :unload }.not_to raise_error
    expect { resource.action :delete }.to raise_error(ArgumentError)
  end
end
