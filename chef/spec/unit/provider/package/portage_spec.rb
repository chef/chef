#
# Author:: Caleb Tennis (<caleb.tennis@gmail.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

describe Chef::Provider::Package::Portage, "load_current_resource" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    
    @new_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "dev-util/git",
      :version => nil,
      :package_name => "dev-util/git",
      :updated => nil
    )
    @current_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "dev-util/git",
      :version => nil,
      :package_name => nil,
      :updated => nil
    )
    
    @provider = Chef::Provider::Package::Portage.new(@node, @new_resource)
    Chef::Resource::Package.stub!(:new).and_return(@current_resource)
    
    ::File.stub!(:exists?).and_return(true)
  end
  
  it "should create a current resource with the name of new_resource" do
    ::Dir.stub!(:entries).and_return("git-1.0.0")
    Chef::Resource::Package.should_receive(:new).and_return(@current_resource)
    @provider.load_current_resource
  end
  
  it "should set the current resource package name to the new resource package name" do
    ::Dir.stub!(:entries).and_return("git-1.0.0")
    @current_resource.should_receive(:package_name).with(@new_resource.package_name)
    @provider.load_current_resource
  end
  
  it "should return a current resource with a nil version if the package is not found" do
    ::Dir.stub!(:entries).and_return("git-1.0.0")
    @current_resource.should_receive(:version).with("1.0.0")
    @provider.load_current_resource
  end

  it "should return a current resource with the correct version if the package is found" do
    ::Dir.stub!(:entries).and_return("notgit-1.0.0")
    @current_resource.should_receive(:version).with(nil)
    @provider.load_current_resource
  end

end

describe Chef::Provider::Package::Portage, "candidate_version" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "dev-util/git",
      :version => nil,
      :package_name => "dev-util/git",
      :updated => nil
    )
    @provider = Chef::Provider::Package::Portage.new(@node, @new_resource)
  end
  
  it "should return the candidate_version variable if already setup" do
    @provider.candidate_version = "1.0.0"
    @provider.should_not_receive(:popen4)
    @provider.candidate_version
  end

  it "should lookup the candidate_version if the variable is not already set" do
    @status = mock("Status", :exitstatus => 0)
    @provider.stub!(:popen4).and_return(@status)
    @provider.should_receive(:popen4)
    @provider.candidate_version
  end

  it "should throw and exception if the exitstatus is not 0" do
    @status = mock("Status", :exitstatus => 1)
    @provider.stub!(:popen4).and_return(@status)
    lambda { @provider.candidate_version }.should raise_error(Chef::Exceptions::Package)
  end
  
end

describe Chef::Provider::Package::Portage, "install_package" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "dev-util/git",
      :version => nil,
      :package_name => "dev-util/git",
      :updated => nil,
      :options => nil
    )
    @provider = Chef::Provider::Package::Portage.new(@node, @new_resource)
  end

  it "should install a normally versioned package using portage" do
    @provider.should_receive(:run_command).with({
      :command => "emerge -g --color n --nospinner --quiet =dev-util/git-1.0.0"
    })
    @provider.install_package("dev-util/git", "1.0.0")
  end

  it "should install a tilde versioned package using portage" do
    @provider.should_receive(:run_command).with({
      :command => "emerge -g --color n --nospinner --quiet ~dev-util/git-1.0.0"
    })
    @provider.install_package("dev-util/git", "~1.0.0")
  end

  it "should add options to the emerge command when specified" do
    @provider.should_receive(:run_command).with({
      :command => "emerge -g --color n --nospinner --quiet --oneshot =dev-util/git-1.0.0"
    })
    @new_resource.stub!(:options).and_return("--oneshot")
    
    @provider.install_package("dev-util/git", "1.0.0")
  end

end

describe Chef::Provider::Package::Portage, "remove_package" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "dev-util/git",
      :version => nil,
      :package_name => "dev-util/git",
      :updated => nil,
      :options => nil
    )
    @provider = Chef::Provider::Package::Portage.new(@node, @new_resource)
  end

  it "should un-emerge the package with no version specified" do
    @provider.should_receive(:run_command).with({
      :command => "emerge --unmerge --color n --nospinner --quiet dev-util/git"
    })
    @provider.remove_package("dev-util/git", nil)
  end

  it "should un-emerge the package with a version specified" do
    @provider.should_receive(:run_command).with({
      :command => "emerge --unmerge --color n --nospinner --quiet =dev-util/git-1.0.0"
    })
    @provider.remove_package("dev-util/git", "1.0.0")
  end
end

