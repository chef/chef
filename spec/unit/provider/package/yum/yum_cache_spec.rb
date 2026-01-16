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

describe Chef::Provider::Package::Yum::YumCache do
  let(:yum_cache) { Chef::Provider::Package::Yum::YumCache.instance }

  let(:python_helper) { instance_double(Chef::Provider::Package::Yum::PythonHelper) }

  def yum_version(name, version, arch)
    Chef::Provider::Package::Yum::Version.new(name, version, arch)
  end

  before(:each) do
    allow( yum_cache ).to receive(:python_helper).and_return(python_helper)
  end

  it "package_available? returns false if the helper reports the available version is nil" do
    expect( python_helper ).to receive(:package_query).with(:whatavailable, "foo", arch: nil).and_return( yum_version("foo", nil, nil) )
    expect( yum_cache.package_available?("foo") ).to be false
  end

  it "package_available? returns true if the helper returns an available version" do
    expect( python_helper ).to receive(:package_query).with(:whatavailable, "foo", arch: nil).and_return( yum_version("foo", "1.2.3-1", "x86_64") )
    expect( yum_cache.package_available?("foo") ).to be true
  end

  it "version_available? returns false if the helper reports the available version is nil" do
    expect( python_helper ).to receive(:package_query).with(:whatavailable, "foo", version: "1.2.3", arch: nil).and_return( yum_version("foo", nil, nil) )
    expect( yum_cache.version_available?("foo", "1.2.3") ).to be false
  end

  it "version_available? returns true if the helper returns an available version" do
    expect( python_helper ).to receive(:package_query).with(:whatavailable, "foo", version: "1.2.3", arch: nil).and_return( yum_version("foo", "1.2.3-1", "x86_64") )
    expect( yum_cache.version_available?("foo", "1.2.3") ).to be true
  end

  it "version_available? with an arch returns false if the helper reports the available version is nil" do
    expect( python_helper ).to receive(:package_query).with(:whatavailable, "foo", version: "1.2.3", arch: "x86_64").and_return( yum_version("foo", nil, nil) )
    expect( yum_cache.version_available?("foo", "1.2.3", "x86_64") ).to be false
  end

  it "version_available? with an arch returns true if the helper returns an available version" do
    expect( python_helper ).to receive(:package_query).with(:whatavailable, "foo", version: "1.2.3", arch: "x86_64").and_return( yum_version("foo", "1.2.3-1", "x86_64") )
    expect( yum_cache.version_available?("foo", "1.2.3", "x86_64") ).to be true
  end

  %i{refresh reload reload_installed reload_provides reset reset_installed}.each do |method|
    it "restarts the python helper when #{method} is called" do
      expect( python_helper ).to receive(:restart)
      yum_cache.send(method)
    end
  end

  it "installed_version? returns nil if the helper reports the installed version is nil" do
    expect( python_helper ).to receive(:package_query).with(:whatinstalled, "foo", arch: nil).and_return( yum_version("foo", nil, nil) )
    expect( yum_cache.installed_version("foo") ).to be nil
  end

  it "installed_version? returns version string if the helper returns an installed version" do
    expect( python_helper ).to receive(:package_query).with(:whatinstalled, "foo", arch: nil).and_return( yum_version("foo", "1.2.3-1", "x86_64") )
    expect( yum_cache.installed_version("foo") ).to eql("1.2.3-1.x86_64")
  end

  it "installed_version? returns nil if the helper reports the installed version is nil" do
    expect( python_helper ).to receive(:package_query).with(:whatinstalled, "foo", arch: "x86_64").and_return( yum_version("foo", nil, nil) )
    expect( yum_cache.installed_version("foo", "x86_64") ).to be nil
  end

  it "installed_version? returns version string if the helper returns an installed version" do
    expect( python_helper ).to receive(:package_query).with(:whatinstalled, "foo", arch: "x86_64").and_return( yum_version("foo", "1.2.3-1", "x86_64") )
    expect( yum_cache.installed_version("foo", "x86_64") ).to eql("1.2.3-1.x86_64")
  end

  it "available_version? returns nil if the helper reports the available version is nil" do
    expect( python_helper ).to receive(:package_query).with(:whatavailable, "foo", arch: nil).and_return( yum_version("foo", nil, nil) )
    expect( yum_cache.available_version("foo") ).to be nil
  end

  it "available_version? returns version string if the helper returns an available version" do
    expect( python_helper ).to receive(:package_query).with(:whatavailable, "foo", arch: nil).and_return( yum_version("foo", "1.2.3-1", "x86_64") )
    expect( yum_cache.available_version("foo") ).to eql("1.2.3-1.x86_64")
  end

  it "available_version? returns nil if the helper reports the available version is nil" do
    expect( python_helper ).to receive(:package_query).with(:whatavailable, "foo", arch: "x86_64").and_return( yum_version("foo", nil, nil) )
    expect( yum_cache.available_version("foo", "x86_64") ).to be nil
  end

  it "available_version? returns version string if the helper returns an available version" do
    expect( python_helper ).to receive(:package_query).with(:whatavailable, "foo", arch: "x86_64").and_return( yum_version("foo", "1.2.3-1", "x86_64") )
    expect( yum_cache.available_version("foo", "x86_64") ).to eql("1.2.3-1.x86_64")
  end
end
