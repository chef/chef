#
# Author:: Jan Zimmek (<jan.zimmek@web.de>)
# Copyright:: Copyright (c) 2010 Jan Zimmek
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

describe Chef::Provider::Package::Pacman, "load_current_resource" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "nano",
      :version => nil,
      :package_name => "nano",
      :updated => nil
    )
    @current_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "nano",
      :version => nil,
      :package_name => nil,
      :updated => nil
    )
    @status = mock("Status", :exitstatus => 0)
    @provider = Chef::Provider::Package::Pacman.new(@node, @new_resource)
    Chef::Resource::Package.stub!(:new).and_return(@current_resource)
    @provider.stub!(:popen4).and_return(@status)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)    
    @stdout.stub!(:each).and_yield("error: package \"nano\" not found")
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
  end
  
  it "should create a current resource with the name of the new_resource" do
    Chef::Resource::Package.should_receive(:new).and_return(@current_resource)
    @provider.load_current_resource
  end
  
  it "should set the current resources package name to the new resources package name" do
    @current_resource.should_receive(:package_name).with(@new_resource.package_name)
    @provider.load_current_resource
  end
  
  it "should run pacman query with the package name" do
    @provider.should_receive(:popen4).with("pacman -Qi #{@new_resource.package_name}").and_return(@status)
    @provider.load_current_resource
  end
  
  it "should read stdout on pacman" do
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @stdout.should_receive(:each).and_return(true)
    @provider.load_current_resource
  end
    
  it "should set the installed version to nil on the current resource if pacman installed version not exists" do
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @current_resource.should_receive(:version).with(nil).and_return(true)
    @provider.load_current_resource
  end
  
  it "should set the installed version if pacman has one" do
    @stdout.stub!(:each).and_yield("Name           : nano").
                         and_yield("Version        : 2.2.2-1").
                         and_yield("URL            : http://www.nano-editor.org").
                         and_yield("Licenses       : GPL  ").
                         and_yield("Groups         : base  ").
                         and_yield("Provides       : None").
                         and_yield("Depends On     : glibc  ncurses  ").
                         and_yield("Optional Deps  : None").
                         and_yield("Required By    : None").
                         and_yield("Conflicts With : None").
                         and_yield("Replaces       : None").
                         and_yield("Installed Size : 1496.00 K").
                         and_yield("Packager       : Andreas Radke <andyrtr@archlinux.org>").
                         and_yield("Architecture   : i686").
                         and_yield("Build Date     : Mon 18 Jan 2010 06:16:16 PM CET").
                         and_yield("Install Date   : Mon 01 Feb 2010 10:06:30 PM CET").
                         and_yield("Install Reason : Explicitly installed").
                         and_yield("Install Script : Yes").
                         and_yield("Description    : Pico editor clone with enhancements                         ")
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @current_resource.should_receive(:version).with("2.2.2-1").and_return(true)
    @provider.load_current_resource
  end
  
  it "should set the candidate version if pacman has one" do
    @stdout.stub!(:each).and_yield("core/nano 2.2.3-1 (base)").
                          and_yield("    Pico editor clone with enhancements").
                          and_yield("community/nanoblogger 3.4.1-1").
                          and_yield("    NanoBlogger is a small weblog engine written in Bash for the command line")
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @provider.load_current_resource
    @provider.candidate_version.should eql("2.2.3-1")
  end
  
  it "should raise an exception if pacman fails" do
    @status.should_receive(:exitstatus).and_return(2)
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Package)
  end
  
  it "should not raise an exception if pacman succeeds" do
    @status.should_receive(:exitstatus).and_return(0)
    lambda { @provider.load_current_resource }.should_not raise_error(Chef::Exceptions::Package)
  end
  
  it "should raise an exception if pacman does not return a candidate version" do
    @stdout.stub!(:each).and_yield("")
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    lambda { @provider.candidate_version }.should raise_error(Chef::Exceptions::Package)
  end
  
  it "should return the current resouce" do
    @provider.load_current_resource.should eql(@current_resource)
  end
end

describe Chef::Provider::Package::Pacman, "install_package" do
  
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "nano",
      :version => nil,
      :package_name => "nano",
      :updated => nil,
      :options => nil
    )
    @provider = Chef::Provider::Package::Pacman.new(@node, @new_resource)
  end
  
  it "should run pacman install with the package name and version" do
    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "pacman --sync --noconfirm --noprogressbar nano"
    })
    @provider.install_package("nano", "1.0")
  end

  it "should run pacman install with the package name and version and options if specified" do
    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "pacman --sync --noconfirm --noprogressbar --debug nano"
    })
    @new_resource.stub!(:options).and_return("--debug")
    
    @provider.install_package("nano", "1.0")
  end
end

describe Chef::Provider::Package::Pacman, "upgrade_package" do
  
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "nano",
      :version => nil,
      :package_name => "nano",
      :updated => nil,
      :options => nil
    )
    @provider = Chef::Provider::Package::Pacman.new(@node, @new_resource)
  end
  
  it "should run install_package with the name and version" do
    @provider.should_receive(:install_package).with("nano", "1.0")
    @provider.upgrade_package("nano", "1.0")
  end
end

describe Chef::Provider::Package::Pacman, "remove_package" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "nano",
      :version => nil,
      :package_name => "nano",
      :updated => nil,
      :options => nil
    )
    @provider = Chef::Provider::Package::Pacman.new(@node, @new_resource)
  end
  
  it "should run pacman remove with the package name" do
    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "pacman --remove --noconfirm --noprogressbar nano"
    })
    @provider.remove_package("nano", "1.0")
  end

  it "should run pacman remove with the package name and options if specified" do
    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "pacman --remove --noconfirm --noprogressbar --debug nano"
    })
    @new_resource.stub!(:options).and_return("--debug")

    @provider.remove_package("nano", "1.0")
  end
end

describe Chef::Provider::Package::Pacman, "purge_package" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "nano",
      :version => nil,
      :package_name => "nano",
      :updated => nil,
      :options => nil
    )
    @provider = Chef::Provider::Package::Pacman.new(@node, @new_resource)
  end
  
  it "should run remove_package with the name and version" do
    @provider.should_receive(:remove_package).with("nano", "1.0")
    @provider.purge_package("nano", "1.0")
  end

end