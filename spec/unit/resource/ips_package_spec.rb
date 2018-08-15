#
# Author:: Bryan McLellan <btm@chef.io>
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

describe Chef::Resource::IpsPackage do
  static_provider_resolution(
    resource: Chef::Resource::IpsPackage,
    provider: Chef::Provider::Package::Ips,
    name: :ips_package,
    action: :install,
    os: "solaris2"
  )

  let(:resource) { Chef::Resource::IpsPackage.new("crypto/gnupg") }

  it "is a subclass of Chef::Resource::Package" do
    expect(resource).to be_a_kind_of(Chef::Resource::Package)
  end

  it "should support accept_license" do
    resource.accept_license(true)
    expect(resource.accept_license).to eql(true)
  end

  it "sets the default action as :install" do
    expect(resource.action).to eql([:install])
  end

  it "supports :install, :lock, :purge, :reconfig, :remove, :unlock, :upgrade actions" do
    expect { resource.action :install }.not_to raise_error
    expect { resource.action :lock }.not_to raise_error
    expect { resource.action :purge }.not_to raise_error
    expect { resource.action :reconfig }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
    expect { resource.action :unlock }.not_to raise_error
    expect { resource.action :upgrade }.not_to raise_error
  end
end
