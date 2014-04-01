#
# Authors:: Richard Manyanza (liseki@nyikacraftsmen.com)
# Copyright:: Copyright (c) 2014 Richard Manyanza
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
require 'ostruct'

describe Chef::Provider::Package::Freebsd::Port do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Package.new("zsh")
    @provider = Chef::Provider::Package::Freebsd::Port.new(@new_resource, @run_context)
  end


  describe "initialization" do
    it "should create a current resource with the name of the new resource" do
      @provider.current_resource.is_a?(Chef::Resource::Package).should be_true
      @provider.current_resource.name.should == 'zsh'
    end
  end


  describe "loading current resource" do
    before(:each) do
      @provider.stub(:current_installed_version)
      @provider.stub(:candidate_version)
    end

    it "should set the package name" do
      @provider.load_current_resource
      @provider.current_resource.package_name.should == "zsh"
    end

    it "should set the current version" do
      @provider.should_receive(:current_installed_version).and_return("5.0.2")
      @provider.load_current_resource
      @provider.current_resource.version.should == "5.0.2"
    end

    it "should set the candidate version" do
      @provider.should_receive(:candidate_version).and_return("5.0.5")
      @provider.load_current_resource
      @provider.instance_variable_get(:"@candidate_version").should == "5.0.5"
    end
  end


  describe "determining current installed version" do
    before(:each) do
      @provider.stub(:supports_pkgng?)
      @pkg_info = OpenStruct.new(:stdout => "zsh-3.1.7\n")
    end

    it "should check 'pkg_info' if system uses pkg_* tools" do
      @provider.should_receive(:supports_pkgng?).and_return(false)
      @provider.should_receive(:shell_out!).with('pkg_info -E "zsh*"', :env => nil, :returns => [0,1]).and_return(@pkg_info)
      @provider.current_installed_version.should == "3.1.7"
    end

    it "should check 'pkg info' if system uses pkgng" do
      @provider.should_receive(:supports_pkgng?).and_return(true)
      @provider.should_receive(:shell_out!).with('pkg info "zsh"', :env => nil, :returns => [0,70]).and_return(@pkg_info)
      @provider.current_installed_version.should == "3.1.7"
    end
  end


  describe "determining candidate version" do
    before(:each) do
      @port_version = OpenStruct.new(:stdout => "5.0.5\n", :exitstatus => 0)
    end

    it "should return candidate version if port exists" do
      ::File.stub(:exist?).with('/usr/ports/Makefile').and_return(true)
      @provider.stub(:port_dir).and_return('/usr/ports/shells/zsh')
      @provider.should_receive(:shell_out!).with("make -V PORTVERSION", :cwd => "/usr/ports/shells/zsh", :env => nil, :returns => [0,1]).
        and_return(@port_version)
      @provider.candidate_version.should == "5.0.5"
    end

    it "should raise exception if ports tree not found" do
      ::File.stub(:exist?).with('/usr/ports/Makefile').and_return(false)
      expect { @provider.candidate_version }.to raise_error(Chef::Exceptions::Package, "Ports collection could not be found")
    end
  end


  describe "determining port directory" do
    it "should return name if package name is absolute path" do
      @provider.new_resource.stub(:package_name).and_return("/var/ports/shells/zsh")
      @provider.port_dir.should == "/var/ports/shells/zsh"
    end

    it "should return full ports path given package name and category" do
      @provider.new_resource.stub(:package_name).and_return("shells/zsh")
      @provider.port_dir.should == "/usr/ports/shells/zsh"
    end

    it "should query system for path given just a name" do
      whereis = OpenStruct.new(:stdout => "zsh: /usr/ports/shells/zsh\n")
      @provider.should_receive(:shell_out!).with("whereis -s zsh", :env => nil).and_return(whereis)
      @provider.port_dir.should == "/usr/ports/shells/zsh"
    end

    it "should raise exception if not found" do
      whereis = OpenStruct.new(:stdout => "zsh:\n")
      @provider.should_receive(:shell_out!).with("whereis -s zsh", :env => nil).and_return(whereis)
      expect { @provider.port_dir }.to raise_error(Chef::Exceptions::Package, "Could not find port with the name zsh")
    end
  end


  describe "building a binary package" do
    before(:each) do
      @install_result = OpenStruct.new(:status => true)
    end

    it "should run make install in port directory" do
      @provider.stub(:port_dir).and_return("/usr/ports/shells/zsh")
      @provider.should_receive(:shell_out!).
        with("make -DBATCH install clean", :timeout => 1800, :cwd => "/usr/ports/shells/zsh", :env => nil).
        and_return(@install_result)
      @provider.install_package("zsh", "5.0.5")
    end
  end


  describe "removing a binary package" do
    before(:each) do
      @install_result = OpenStruct.new(:status => true)
    end

    it "should run make deinstall in port directory" do
      @provider.stub(:port_dir).and_return("/usr/ports/shells/zsh")
      @provider.should_receive(:shell_out!).
        with("make deinstall", :timeout => 300, :cwd => "/usr/ports/shells/zsh", :env => nil).
        and_return(@install_result)
      @provider.remove_package("zsh", "5.0.5")
    end
  end
end
