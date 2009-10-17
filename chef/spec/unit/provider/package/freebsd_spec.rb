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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper"))

describe Chef::Provider::Package::Freebsd, "load_current_resource" do
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

    @provider = Chef::Provider::Package::Freebsd.new(@node, @new_resource)    
    Chef::Resource::Package.stub!(:new).and_return(@current_resource)

    @provider.should_receive(:ports_candidate_version).and_return("4.3.6")
  end

  it "should create a current resource with the name of the new_resource" do
    Chef::Resource::Package.should_receive(:new).and_return(@current_resource)
    @provider.should_receive(:current_installed_version).and_return(nil)
    @provider.load_current_resource
  end

  it "should return a version if the package is installed" do
    @provider.should_receive(:current_installed_version).and_return("4.3.6_7")
    @current_resource.should_receive(:version).with("4.3.6_7").and_return(true)
    @provider.load_current_resource
  end

  it "should return nil if the package is not installed" do
    @provider.should_receive(:current_installed_version).and_return(nil)
    @current_resource.should_receive(:version).with(nil).and_return(true)
    @provider.load_current_resource
  end

  it "should return a candidate version if it exists" do
    @provider.should_receive(:current_installed_version).and_return(nil)
    @provider.load_current_resource
    @provider.candidate_version.should eql("4.3.6")
  end
end

describe Chef::Provider::Package::Freebsd, "system call wrappers" do
  before(:each) do
    @new_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "zsh",
      :package_name => "zsh",
      :version => nil
    )

    @provider = Chef::Provider::Package::Freebsd.new(@node, @new_resource)    

    @status = mock("Status", :exitstatus => 0)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
  end

  it "should return the version number when it is installed" do
    @provider.should_receive(:popen4).with('pkg_info -E "zsh*"').and_yield(@pid, @stdin, ["zsh-4.3.6_7"], @stderr).and_return(@status)
    @provider.stub!(:package_name).and_return("zsh")
    @provider.current_installed_version.should == "4.3.6_7"
  end

  it "should return nil when the package is not installed" do
    @provider.should_receive(:popen4).with('pkg_info -E "zsh*"').and_yield(@pid, @stdin, [], @stderr).and_return(@status)
    @provider.stub!(:package_name).and_return("zsh")
    @provider.current_installed_version.should be_nil
  end
  
  it "should return the port path for a valid port name" do
    @provider.should_receive(:popen4).with("whereis -s zsh").and_yield(@pid, @stdin, ["zsh: /usr/ports/shells/zsh"], @stderr).and_return(@status)
    @provider.stub!(:port_name).and_return("zsh")
    @provider.port_path.should == "/usr/ports/shells/zsh"
  end

  # Not happy with the form of these tests as they are far too closely tied to the implementation and so very fragile.
  it "should return the ports candidate version when given a valid port path" do
    @provider.should_receive(:port_path).and_return("/usr/ports/shells/zsh")
    @provider.should_receive(:popen4).with("cd /usr/ports/shells/zsh; make -V PORTVERSION").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @stdout.should_receive(:readline).and_return("4.3.6\n")
    @provider.ports_candidate_version.should == "4.3.6"
  end
  
  it "should figure out the package name" do
    @provider.should_receive(:ports_makefile_variable_value).with("PKGNAME").and_return("zsh-4.3.6_7")
    @provider.package_name.should == "zsh"
  end
end

describe Chef::Provider::Package::Freebsd, "install_package" do
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
    @provider = Chef::Provider::Package::Freebsd.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:package_name).and_return("zsh")
    @provider.stub!(:latest_link_name).and_return("zsh")
  end

  it "should run pkg_add -r with the package name" do
    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "pkg_add -r zsh",
    })
    @provider.install_package("zsh", "4.3.6_7")
  end

  it "should run make install when installing from ports" do
    @new_resource.stub!(:source).and_return("ports")
    @provider.should_receive(:port_path).and_return("/usr/ports/shells/zsh")
    @provider.should_receive(:run_command_with_systems_locale).with(:command => "make -DBATCH install", :cwd => "/usr/ports/shells/zsh")
    @provider.install_package("zsh", "4.3.6_7")
  end
end

describe Chef::Provider::Package::Freebsd, "port path" do
  it "should figure out the port path from the package_name using whereis" do
    @new_resource = mock( "Chef::Resource::Package", 
                          :package_name => "zsh", 
                          :cookbook_name => "adventureclub")
    @provider = Chef::Provider::Package::Freebsd.new(mock("Chef::Node"), @new_resource)
    @provider.should_receive(:popen4).with("whereis -s zsh").and_yield(nil, nil, ["zsh: /usr/ports/shells/zsh"], nil)
    @provider.port_path.should == "/usr/ports/shells/zsh"
  end
  
  it "should use the package_name as the port path when it starts with /" do
    @new_resource = mock( "Chef::Resource::Package", 
                          :package_name => "/usr/ports/www/wordpress",
                          :cookbook_name => "adventureclub")
    @provider = Chef::Provider::Package::Freebsd.new(mock("Chef::Node"), @new_resource)
    @provider.should_not_receive(:popen4)
    @provider.port_path.should == "/usr/ports/www/wordpress"
  end
  
  it "should use the package_name as a relative path from /usr/ports when it contains / but doesn't start with it" do
    @new_resource = mock( "Chef::Resource::Package", 
                          :package_name => "www/wordpress",
                          :cookbook_name => "xenoparadox")
    @provider = Chef::Provider::Package::Freebsd.new(mock("Chef::Node"), @new_resource)
    @provider.should_not_receive(:popen4)
    @provider.port_path.should == "/usr/ports/www/wordpress"
  end 
end

describe Chef::Provider::Package::Freebsd, "ruby-iconv (package with a dash in the name)" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "ruby-iconv",
      :package_name => "ruby-iconv",
      :version => nil
    )
    @current_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "ruby-iconv",
      :package_name => "ruby-iconv",
      :version => nil
    )
    @provider = Chef::Provider::Package::Freebsd.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:port_path).and_return("/usr/ports/converters/ruby-iconv")
    @provider.stub!(:package_name).and_return("ruby18-iconv")
    @provider.stub!(:latest_link_name).and_return("ruby18-iconv")
  end

  it "should run pkg_add -r with the package name" do
    @provider.should_receive(:run_command_with_systems_locale).with(:command => "pkg_add -r ruby18-iconv")
    @provider.install_package("ruby-iconv", "1.0")
  end

  it "should run make install when installing from ports" do
    @new_resource.stub!(:source).and_return("ports")
    @provider.should_receive(:run_command_with_systems_locale).with(:command => "make -DBATCH install", :cwd => "/usr/ports/converters/ruby-iconv")
    @provider.install_package("ruby-iconv", "1.0")
  end
end

describe Chef::Provider::Package::Freebsd, "remove_package" do
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
    @provider = Chef::Provider::Package::Freebsd.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:package_name).and_return("zsh")
  end

  it "should run pkg_delete with the package name and version" do
    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "pkg_delete zsh-4.3.6_7"
    })
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
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "perl5.8",
      :package_name => "perl5.8",
      :version => nil
    )
    @current_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "perl5.8",
      :package_name => "perl5.8",
      :version => nil
    )
    @provider = Chef::Provider::Package::Freebsd.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:package_name).and_return("perl")
    @provider.stub!(:latest_link_name).and_return("perl")

    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "pkg_add -r perl",
    })
    @provider.install_package("perl5.8", "5.8.8_1")
  end

  it "should install the mysql50-server binary package with the correct name" do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Package",
      :null_object => true,
      :name => "mysql50-server",
      :package_name => "mysql50-server",
      :version => nil
    )
    @current_resource = mock("Chef::Resource::Package", 
      :null_object => true,
      :name => "mysql50-server",
      :package_name => "mysql50-server",
      :version => nil
    )
    @provider = Chef::Provider::Package::Freebsd.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:package_name).and_return("mysql-server")
    @provider.stub!(:latest_link_name).and_return("mysql50-server")

    @provider.should_receive(:run_command_with_systems_locale).with({
      :command => "pkg_add -r mysql50-server",
    })
    @provider.install_package("mysql50-server", "5.0.45_1")
  end
end

