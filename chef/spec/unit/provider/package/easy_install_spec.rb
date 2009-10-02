#
# Author:: David Balatero (dbalatero@gmail.com)
#
# Copyright:: Copyright (c) 2009 David Balatero
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper"))

describe Chef::Provider::Package::EasyInstall, "easy_install_binary_path" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "boto",
      :version => "1.8d",
      :package_name => "boto",
      :easy_install_binary => nil
    )
    @provider = Chef::Provider::Package::EasyInstall.new(@node, @new_resource)
  end

  it "should return a relative path to easy_install if no easy_install_binary is given" do
    @provider.easy_install_binary_path.should eql("easy_install")
  end

  it "should return a specific path to easy_install if a easy_install_binary is given" do
    @new_resource.should_receive(:easy_install_binary).and_return("/opt/local/bin/custom/easy_install")
    @provider.easy_install_binary_path.should eql("/opt/local/bin/custom/easy_install")
  end
end

describe Chef::Provider::Package::EasyInstall, "install_package" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "boto",
      :version => "1.8d",
      :package_name => "boto",
      :easy_install_binary => nil
    )
    @provider = Chef::Provider::Package::EasyInstall.new(@node, @new_resource)
  end

  it "should run gem install with the package name and version" do
    @provider.should_receive(:run_command).with({
      :command => "easy_install \"boto==1.8d\""
    })
    @provider.install_package("boto", "1.8d")
  end
end
