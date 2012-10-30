#
# Author:: Joe Williams (<joe@joetify.com>)
# Copyright:: Copyright (c) 2009 Joe Williams
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

require 'spec_helper'

describe Chef::Resource::EasyInstallPackage, "initialize" do

  before(:each) do
    @resource = Chef::Resource::EasyInstallPackage.new("foo")
  end

  it "should create a new Chef::Resource::EasyInstallPackage" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::EasyInstallPackage)
  end

  it "should return a Chef::Resource::EasyInstallPackage" do
    @resource.should be_a_kind_of(Chef::Resource::EasyInstallPackage)
  end

  it "should set the resource_name to :easy_install_package" do
    @resource.resource_name.should eql(:easy_install_package)
  end

  it "should set the provider to Chef::Provider::Package::EasyInstall" do
    @resource.provider.should eql(Chef::Provider::Package::EasyInstall)
  end

  it "should allow you to set the easy_install_binary attribute" do
    @resource.easy_install_binary "/opt/local/bin/easy_install"
    @resource.easy_install_binary.should eql("/opt/local/bin/easy_install")
  end
end
