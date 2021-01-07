#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com>)
# Copyright:: Copyright 2010-2016, Thomas Bishop
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
require "support/shared/unit/resource/static_provider_resolution"

describe Chef::Resource::RpmPackage, "initialize" do

  %w{linux aix}.each do |os|
    static_provider_resolution(
      resource: Chef::Resource::RpmPackage,
      provider: Chef::Provider::Package::Rpm,
      name: :rpm_package,
      action: :install,
      os: os
    )
  end

end

describe Chef::Resource::RpmPackage, "allow_downgrade" do
  let(:resource) { Chef::Resource::RpmPackage.new("foo") }

  it "is a subclass of Chef::Resource::Package" do
    expect(resource).to be_a_kind_of(Chef::Resource::Package)
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

  it "allows you to specify whether allow_downgrade is true or false" do
    expect { resource.allow_downgrade true }.not_to raise_error
    expect { resource.allow_downgrade false }.not_to raise_error
    expect { resource.allow_downgrade "monkey" }.to raise_error(ArgumentError)
  end
end
