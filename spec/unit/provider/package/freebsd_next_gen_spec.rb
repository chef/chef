#
# Authors:: Richard Manyanza (liseki@nyikacraftsmen.com)
# Copyright:: Copyright (c) 2013 Richard Manyanza
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


describe Chef::Provider::Package::FreebsdNextGen do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Package.new("zsh")
    @provider = Chef::Provider::Package::FreebsdNextGen.new(@new_resource, @run_context)
  end


  describe "initialization" do
    it "should create a current resource with the name of the new resource" do
      @provider.current_resource.is_a?(Chef::Resource::Package).should be_true
      @provider.current_resource.name.should == 'zsh'
    end
  end


  describe "loading current resource" do
    before(:each) do
      @provider.stub!(:current_installed_version).and_return(nil)
      @provider.stub!(:ports_candidate_version).and_return("5.0.2_1")
      @provider.stub!(:repo_candidate_version).and_return("5.0.2_5")
    end

    it "should set current version if the package is installed" do
      @provider.should_receive(:current_installed_version).and_return("5.0.2")
      @provider.load_current_resource
      @provider.current_resource.version.should == "5.0.2"
    end

    it "should not set current version if the package is not installed" do
      @provider.load_current_resource
      @provider.current_resource.version.should be_nil
    end

    it "should set candidate version from port if building port" do
      @new_resource.source('ports')
      @provider.load_current_resource
      @provider.candidate_version.should == "5.0.2_1"
    end

    it "should set candidate version from file if adding local or remote package" do
      @new_resource.source('/root/packages/zsh-5.0.2_3.txz')
      @provider.load_current_resource
      @provider.candidate_version.should == "5.0.2_3"
    end
  end


  describe "querying repository for package version" do
    before(:each) do
      @provider.stub!(:current_installed_version).and_return(nil)
      @pkg_query = OpenStruct.new(:stdout => "5.0.2_1")
    end

    it "should make call to repository" do
      @provider.should_receive(:shell_out!).with("pkg rquery '%v' zsh", :env => nil, :returns => [0,69]).and_return(@pkg_query)
      @provider.load_current_resource
      @provider.candidate_version.should == "5.0.2_1"
    end

    it "should be able to use custom repository option" do
      @provider.should_receive(:shell_out!).with("pkg rquery -r http://pkgrepo.example.com '%v' zsh", :env => nil, :returns => [0,69]).and_return(@pkg_query)
      @new_resource.options('-r http://pkgrepo.example.com')
      @provider.load_current_resource
    end
  end


  describe "querying package state" do
    it "should return version number if package is installed" do
      pkg_info = OpenStruct.new(:stdout => "zsh-4.3.6_7")
      @provider.should_receive(:shell_out!).with('pkg info "zsh"', :env => nil, :returns => [0,70]).and_return(pkg_info)
      @provider.send(:current_installed_version).should == "4.3.6_7"
    end

    it "should not return a version number if package is not installed" do
      pkg_info = OpenStruct.new(:stdout => "pkg: No package(s) matching zsh")
      @provider.should_receive(:shell_out!).with('pkg info "zsh"', :env => nil, :returns => [0,70]).and_return(pkg_info)
      @provider.send(:current_installed_version).should be_nil
    end

    it "should return the port path for a valid port name" do
      whereis = OpenStruct.new(:stdout => "zsh: /usr/ports/shells/zsh")
      @provider.should_receive(:shell_out!).with("whereis -s zsh", :env => nil).and_return(whereis)
      @provider.send(:port_path).should == '/usr/ports/shells/zsh'
    end

    it "should return the ports candidate version when given a valid port path" do
      @provider.stub!(:port_path).and_return("/usr/ports/shells/zsh")
      make_v = OpenStruct.new(:stdout => "4.3.6\n")
      @provider.should_receive(:shell_out!).with("make -V PORTVERSION", {:cwd=>"/usr/ports/shells/zsh", :returns=>[0, 1], :env=>nil}).and_return(make_v)
      @provider.send(:ports_candidate_version).should == "4.3.6"
    end
  end


  describe "installing a binary package" do
    before do
      @provider.stub!(:current_installed_version).and_return(nil)
      @status = OpenStruct.new(:status => true)
    end

    it "should be able to install from a package repository" do
      @provider.should_receive(:shell_out!).with("pkg install -y zsh", :env => { 'LC_ALL' => nil }).and_return(@status)
      @new_resource.source.should be_nil
      @provider.install_package('zsh', nil)
    end

    it "should be able to install from a custom repository" do
      @provider.should_receive(:shell_out!).with("pkg install -r http://pkgrepo.example.com zsh", :env => { 'LC_ALL' => nil }).and_return(@status)
      @new_resource.source.should be_nil
      @new_resource.options('-r http://pkgrepo.example.com')
      @provider.install_package('zsh', nil)
    end

    it "should be able to install a local package" do
      @provider.should_receive(:shell_out!).with("pkg add /root/packages/zsh-5.0.2.txz", :env => { 'LC_ALL' => nil }).and_return(@status)
      @new_resource.source('/root/packages/zsh-5.0.2.txz')
      @provider.install_package('zsh', '5.0.2')
    end

    it "should be able to install a remote package" do
      @provider.should_receive(:shell_out!).with("pkg add http://pkgrepo.eg.com/All/zsh-5.0.2.txz", :env => { 'LC_ALL' => nil }).and_return(@status)
      @new_resource.source('http://pkgrepo.eg.com/All/zsh-5.0.2.txz')
      @provider.install_package('zsh', '5.0.2')
    end
  end


  describe "building a binary package" do
    before do
      @provider.stub!(:current_installed_version).and_return(nil)
      @status = OpenStruct.new(:status => true)
    end

    it "should handle a regular port name" do
      @provider.should_receive(:shell_out!).with('whereis -s zsh', :env => nil).and_return(OpenStruct.new(:stdout => 'zsh: /usr/ports/shells/zsh'))
      @provider.should_receive(:shell_out!).with('make -DBATCH install', :timeout => 1800, :env => nil, :cwd => '/usr/ports/shells/zsh').and_return(@status)
      @new_resource.source('ports')
      @provider.install_package('zsh', '5.0.2')
    end

    it "should handle a port name including section" do
      @provider.should_receive(:shell_out!).with('make -DBATCH install', :timeout => 1800, :env => nil, :cwd => '/usr/ports/shells/zsh').and_return(@status)
      @new_resource.package_name('shells/zsh')
      @new_resource.source('ports')
      @provider.install_package('zsh', '5.0.2')
    end

    it "should handle a custom port location" do
      @provider.should_receive(:shell_out!).with('make -DBATCH install', :timeout => 1800, :env => nil, :cwd => '/master/ports/shells/zsh').and_return(@status)
      @new_resource.package_name('/master/ports/shells/zsh')
      @new_resource.source('ports')
      @provider.install_package('zsh', '5.0.2')
    end
  end


  describe "removing a binary package" do
    before do
      @status = OpenStruct.new(:status => true)
    end

    it "should be able to remove package with version number" do
      @provider.should_receive(:shell_out!).with("pkg delete -y zsh-5.0.2_1", :env => nil).and_return(@status)
      @provider.remove_package("zsh", "5.0.2_1")
    end

    it "should be able to remove package without version number" do
      @provider.should_receive(:shell_out!).with("pkg delete -y zsh", :env => nil).and_return(@status)
      @provider.remove_package("zsh", nil)
    end

    it "should be able to pass custom options" do
      @provider.should_receive(:shell_out!).with("pkg delete -Df zsh-5.0.2_1", :env => nil).and_return(@status)
      @new_resource.options('-Df')
      @provider.remove_package("zsh", "5.0.2_1")
    end
  end
end
