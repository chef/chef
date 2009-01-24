#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright (c) 2009 Bryan McLellan
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

describe Chef::Provider::Package::Pkg, "load_current_resource" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "zsh",
      :package_name => "zsh",
      :version => nil
    )
    @current_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "zsh",
      :package_name => "zsh",
      :version => nil
    )

    @provider = Chef::Provider::Package::Pkg.new(@node, @new_resource)    
    Chef::Resource::Package.stub!(:new).and_return(@current_resource)
    @status = mock("Status", :exitstatus => 0)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
  end

  it "should create a current resource with the name of the new_resource" do
    Chef::Resource::Package.should_receive(:new).and_return(@current_resource)
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @provider.load_current_resource
  end

  it "should return a version if the package is installed" do
    @stdout.stub!(:each).and_yield("zsh-4.3.6_7")
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @current_resource.should_receive(:version).with("4.3.6_7").and_return(true)
    @provider.load_current_resource
  end

  it "should return nil if the package is not installed" do
    #@stdout.stub!(:each).and_yield("zsh-4.3.6_7")
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @current_resource.should_receive(:version).with(nil).and_return(true)
    @provider.load_current_resource
  end

  it "should return a candidate version if it exists" do
    @stdout.stub!(:each).and_yield("zsh: /usr/ports/shells/zsh")
    #@stdout.stub!(:each).and_yield("PORTVERSION=  4.3.6")
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    File.stub!(:open)
    @makefile.stub!(:each).and_yield("PORTVERSION= 4.3.6")
    @provider.load_current_resource
    @provider.candidate_version.should eql("4.3.6")
  end
end

describe Chef::Provider::Package::Pkg, "install_package" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "zsh",
      :package_name => "zsh",
      :version => nil
    )
    @current_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "zsh",
      :package_name => "zsh",
      :version => nil
    )
    @provider = Chef::Provider::Package::Pkg.new(@node, @new_resource)
    @provider.current_resource = @current_resource
  end

  it "should run pkg_add -r with the package name" do
    @provider.should_receive(:run_command).with({
      :command => "pkg_add -r zsh",
    })
    @provider.install_package("zsh", "4.3.6_7")
  end
end

describe Chef::Provider::Package::Pkg, "remove_package" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "zsh",
      :package_name => "zsh",
      :version => "4.3.6_7"
    )
    @current_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "zsh",
      :package_name => "zsh",
      :version => "4.3.6_7"
    )
    @provider = Chef::Provider::Package::Pkg.new(@node, @new_resource)
    @provider.current_resource = @current_resource
  end

  it "should run pkg_delete with the package name and version" do
    @provider.should_receive(:run_command).with({
      :command => "pkg_delete zsh-4.3.6_7"
    })
    @provider.remove_package("zsh", "4.3.6_7")
  end
end

