#
# Authors:: Bryan McLellan (btm@loftninjas.org)
#           Matthew Landauer (matthew@openaustralia.org)
# Copyright:: Copyright (c) 2009 Bryan McLellan, Matthew Landauer
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

describe Chef::Provider::Package::Freebsd, "load_current_resource" do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource     = Chef::Resource::Package.new("zsh")
    @current_resource = Chef::Resource::Package.new("zsh")

    @provider = Chef::Provider::Package::Freebsd.new(@new_resource, @run_context)
    @provider.current_resource = @current_resource
    ::File.stub!(:exist?).with('/usr/ports/Makefile').and_return(false)
  end

  describe "when determining the current package state" do
    before do
      @provider.stub!(:ports_candidate_version).and_return("4.3.6")
    end

    it "should create a current resource with the name of the new_resource" do
      current_resource = Chef::Provider::Package::Freebsd.new(@new_resource, @run_context).current_resource
      current_resource.name.should == "zsh"
    end

    it "should return a version if the package is installed" do
      @provider.should_receive(:current_installed_version).and_return("4.3.6_7")
      @provider.load_current_resource
      @current_resource.version.should == "4.3.6_7"
    end

    it "should return nil if the package is not installed" do
      @provider.should_receive(:current_installed_version).and_return(nil)
      @provider.load_current_resource
      @current_resource.version.should be_nil
    end

    it "should return a candidate version if it exists" do
      @provider.should_receive(:current_installed_version).and_return(nil)
      @provider.load_current_resource
      @provider.candidate_version.should eql("4.3.6")
    end
  end

  describe "when querying for package state and attributes" do
    before do
      #@new_resource = Chef::Resource::Package.new("zsh")

      #@provider = Chef::Provider::Package::Freebsd.new(@node, @new_resource)

      #@status = mock("Status", :exitstatus => 0)
      #@stdin = mock("STDIN", :null_object => true)
      #@stdout = mock("STDOUT", :null_object => true)
      #@stderr = mock("STDERR", :null_object => true)
      #@pid = mock("PID", :null_object => true)
    end

    it "should return the version number when it is installed" do
      pkg_info = OpenStruct.new(:stdout => "zsh-4.3.6_7")
      @provider.should_receive(:shell_out!).with('pkg_info -E "zsh*"', :env => nil, :returns => [0,1]).and_return(pkg_info)
      #@provider.should_receive(:popen4).with('pkg_info -E "zsh*"').and_yield(@pid, @stdin, ["zsh-4.3.6_7"], @stderr).and_return(@status)
      @provider.stub!(:package_name).and_return("zsh")
      @provider.current_installed_version.should == "4.3.6_7"
    end

    it "does not set the current version number when the package is not installed" do
      pkg_info = OpenStruct.new(:stdout => "")
      @provider.should_receive(:shell_out!).with('pkg_info -E "zsh*"', :env => nil, :returns => [0,1]).and_return(pkg_info)
      @provider.stub!(:package_name).and_return("zsh")
      @provider.current_installed_version.should be_nil
    end

    it "should return the port path for a valid port name" do
      whereis = OpenStruct.new(:stdout => "zsh: /usr/ports/shells/zsh")
      @provider.should_receive(:shell_out!).with("whereis -s zsh", :env => nil).and_return(whereis)
      #@provider.should_receive(:popen4).with("whereis -s zsh").and_yield(@pid, @stdin, ["zsh: /usr/ports/shells/zsh"], @stderr).and_return(@status)
      @provider.stub!(:port_name).and_return("zsh")
      @provider.port_path.should == "/usr/ports/shells/zsh"
    end

    # Not happy with the form of these tests as they are far too closely tied to the implementation and so very fragile.
    it "should return the ports candidate version when given a valid port path" do
      @provider.stub!(:port_path).and_return("/usr/ports/shells/zsh")
      make_v = OpenStruct.new(:stdout => "4.3.6\n")
      @provider.should_receive(:shell_out!).with("make -V PORTVERSION", {:cwd=>"/usr/ports/shells/zsh", :returns=>[0, 1], :env=>nil}).and_return(make_v)
      @provider.ports_candidate_version.should == "4.3.6"
    end

    it "should figure out the package name when we have ports" do
      ::File.stub!(:exist?).with('/usr/ports/Makefile').and_return(true)
      @provider.stub!(:port_path).and_return("/usr/ports/shells/zsh")
      make_v = OpenStruct.new(:stdout => "zsh-4.3.6_7\n")
      @provider.should_receive(:shell_out!).with("make -V PKGNAME", {:cwd=>"/usr/ports/shells/zsh", :env=>nil, :returns=>[0, 1]}).and_return(make_v)
      #@provider.should_receive(:ports_makefile_variable_value).with("PKGNAME").and_return("zsh-4.3.6_7")
      @provider.package_name.should == "zsh"
    end
  end

  describe Chef::Provider::Package::Freebsd, "install_package" do
    before(:each) do
      @cmd_result = OpenStruct.new(:status => true)

      @provider.current_resource = @current_resource
      @provider.stub!(:package_name).and_return("zsh")
      @provider.stub!(:latest_link_name).and_return("zsh")
      @provider.stub!(:port_path).and_return("/usr/ports/shells/zsh")
    end

    it "should run pkg_add -r with the package name" do
      @provider.should_receive(:shell_out!).with("pkg_add -r zsh", :env => nil).and_return(@cmd_result)
      @provider.install_package("zsh", "4.3.6_7")
    end

    it "should run make install when installing from ports" do
      @new_resource.stub!(:source).and_return("ports")
      @provider.should_not_receive(:shell_out!).with("make -DBATCH -f /usr/ports/shells/zsh/Makefile install", :timeout => 1200, :env=>nil)
      @provider.should_receive(:shell_out!).with("make -DBATCH install", :timeout => 1200, :env=>nil, :cwd => @provider.port_path).and_return(@cmd_result)
      @provider.install_package("zsh", "4.3.6_7")
    end
  end

  describe Chef::Provider::Package::Freebsd, "port path" do
    before do
      #@node = Chef::Node.new
      @new_resource = Chef::Resource::Package.new("zsh")
      @new_resource.cookbook_name = "adventureclub"
      @provider = Chef::Provider::Package::Freebsd.new(@new_resource, @run_context)
    end

    it "should figure out the port path from the package_name using whereis" do
      whereis = OpenStruct.new(:stdout => "zsh: /usr/ports/shells/zsh")
      @provider.should_receive(:shell_out!).with("whereis -s zsh", :env=>nil).and_return(whereis)
      @provider.port_path.should == "/usr/ports/shells/zsh"
    end

    it "should use the package_name as the port path when it starts with /" do
      new_resource = Chef::Resource::Package.new("/usr/ports/www/wordpress")
      provider = Chef::Provider::Package::Freebsd.new(new_resource, @run_context)
      provider.should_not_receive(:popen4)
      provider.port_path.should == "/usr/ports/www/wordpress"
    end

    it "should use the package_name as a relative path from /usr/ports when it contains / but doesn't start with it" do
      # @new_resource = mock( "Chef::Resource::Package",
      #                       :package_name => "www/wordpress",
      #                       :cookbook_name => "xenoparadox")
      new_resource = Chef::Resource::Package.new("www/wordpress")
      provider = Chef::Provider::Package::Freebsd.new(new_resource, @run_context)
      provider.should_not_receive(:popen4)
      provider.port_path.should == "/usr/ports/www/wordpress"
    end
  end

  describe Chef::Provider::Package::Freebsd, "ruby-iconv (package with a dash in the name)" do
    before(:each) do
      @new_resource     = Chef::Resource::Package.new("ruby-iconv")
      @current_resource = Chef::Resource::Package.new("ruby-iconv")
      @provider = Chef::Provider::Package::Freebsd.new(@new_resource, @run_context)
      @provider.current_resource = @current_resource
      @provider.stub!(:port_path).and_return("/usr/ports/converters/ruby-iconv")
      @provider.stub!(:package_name).and_return("ruby18-iconv")
      @provider.stub!(:latest_link_name).and_return("ruby18-iconv")

      @install_result = OpenStruct.new(:status => true)
    end

    it "should run pkg_add -r with the package name" do
      @provider.should_receive(:shell_out!).with("pkg_add -r ruby18-iconv", :env => nil).and_return(@install_result)
      @provider.install_package("ruby-iconv", "1.0")
    end

    it "should run make install when installing from ports" do
      @new_resource.stub!(:source).and_return("ports")
      @provider.should_receive(:shell_out!).with("make -DBATCH install", :timeout => 1200, :env=>nil, :cwd => @provider.port_path).and_return(@install_result)
      @provider.install_package("ruby-iconv", "1.0")
    end
  end

  describe Chef::Provider::Package::Freebsd, "remove_package" do
    before(:each) do
      @pkg_delete = OpenStruct.new(:status => true)
      @new_resource.version "4.3.6_7"
      @current_resource.version "4.3.6_7"
      @provider.current_resource = @current_resource
      @provider.stub!(:package_name).and_return("zsh")
    end

    it "should run pkg_delete with the package name and version" do
      @provider.should_receive(:shell_out!).with("pkg_delete zsh-4.3.6_7", :env => nil).and_return(@pkg_delete)
      @provider.remove_package("zsh", "4.3.6_7")
    end
  end

  # A couple of examples to show up the difficulty of determining the command to install the binary package given the port:
  # PORT DIRECTORY                        INSTALLED PACKAGE NAME  COMMAND TO INSTALL PACKAGE
  # /usr/ports/lang/perl5.8               perl-5.8.8_1            pkg_add -r perl
  # /usr/ports/databases/mysql50-server   mysql-server-5.0.45_1   pkg_add -r mysql50-server
  #
  # So, in one case it appears the command to install the package can be derived from the name of the port directory and in the
  # other case it appears the command can be derived from the package name. Very confusing!
  # Well, luckily, after much poking around, I discovered that the two can be disambiguated through the use of the LATEST_LINK
  # variable which is set by the ports Makefile
  #
  # PORT DIRECTORY                        LATEST_LINK     INSTALLED PACKAGE NAME  COMMAND TO INSTALL PACKAGE
  # /usr/ports/lang/perl5.8               perl            perl-5.8.8_1            pkg_add -r perl
  # /usr/ports/databases/mysql50-server   mysql50-server  mysql-server-5.0.45_1   pkg_add -r mysql50-server
  #
  # The variable LATEST_LINK is named that way because the directory that "pkg_add -r" downloads from is called "Latest" and
  # contains the "latest" versions of package as symbolic links to the files in the "All" directory.

  describe Chef::Provider::Package::Freebsd, "install_package latest link fixes" do
    it "should install the perl binary package with the correct name" do
      @new_resource = Chef::Resource::Package.new("perl5.8")
      @current_resource = Chef::Resource::Package.new("perl5.8")
      @provider = Chef::Provider::Package::Freebsd.new(@new_resource, @run_context)
      @provider.current_resource = @current_resource
      @provider.stub!(:package_name).and_return("perl")
      @provider.stub!(:latest_link_name).and_return("perl")

      cmd = OpenStruct.new(:status => true)
      @provider.should_receive(:shell_out!).with("pkg_add -r perl", :env => nil).and_return(cmd)
      @provider.install_package("perl5.8", "5.8.8_1")
    end

    it "should install the mysql50-server binary package with the correct name" do

      @new_resource     = Chef::Resource::Package.new("mysql50-server")
      @current_resource = Chef::Resource::Package.new("mysql50-server")
      @provider = Chef::Provider::Package::Freebsd.new(@new_resource, @run_context)
      @provider.current_resource = @current_resource
      @provider.stub!(:package_name).and_return("mysql-server")
      @provider.stub!(:latest_link_name).and_return("mysql50-server")

      cmd = OpenStruct.new(:status => true)
      @provider.should_receive(:shell_out!).with("pkg_add -r mysql50-server", :env=>nil).and_return(cmd)
      @provider.install_package("mysql50-server", "5.0.45_1")
    end
  end
end
