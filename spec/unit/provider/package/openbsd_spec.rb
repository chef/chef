#
# Author:: Scott Bonds (scott@ggr.com)
# Copyright:: Copyright (c) 2014 Scott Bonds
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

def running_compatible_os
  @os ||= `uname`.downcase.strip
  @os_version ||= `uname -r`.strip
  @os_architecture ||= `uname -m`.downcase.strip
  @os == 'openbsd' && @os_version == '5.5' && @os_architecture == 'amd64'
end

describe Chef::Provider::Package::Openbsd, 'find_package', :if => running_compatible_os do

  before(:each) do
    @node = Chef::Node.new
    @node.default['kernel'] = {'name' => 'OpenBSD', 'release' => '5.5', 'machine' => 'amd64'}
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
  end

  describe "plain package name (zsh)" do
    before do
      @name = 'zsh'
      @new_resource     = Chef::Resource::Package.new(@name)
      @current_resource = Chef::Resource::Package.new(@name)
      @provider = Chef::Provider::Package::Openbsd.new(@new_resource, @run_context)
      @provider.current_resource = @current_resource
      @provider.sqlports(:skip_installation => true)
      @info = @provider.find_package(@name)
    end

    it "should parse as a plain package with no version" do
      @info[:short_name].should     == 'zsh'
      @info[:short_version].should  == '5.0.2'
      @info[:pkgspec].should        == 'zsh-*'
      @info[:fullpkgname].should    == 'zsh-5.0.2'
      @info[:fullpkgpath].should    == 'shells/zsh'
    end

    it "should translate to a port path" do
      @provider.port_path.should == '/usr/ports/shells/zsh'
    end

    it "should have a valid repo candidate version" do
      @provider.repo_candidate_version.should == '5.0.2'
    end

    it "should have a valid port candidate version" do
      @provider.port_candidate_version.should == '5.0.2'
    end

  end

  describe "package name with unavailable version (zsh-5.0.10)" do
    before do
      @name = 'zsh-5.0.10'
      @new_resource     = Chef::Resource::Package.new(@name)
      @current_resource = Chef::Resource::Package.new(@name)
      @provider = Chef::Provider::Package::Openbsd.new(@new_resource, @run_context)
      @provider.current_resource = @current_resource
      @provider.sqlports(:skip_installation => true)
    end

    it "should raise an exception when the requested version does not match whats available in the repo" do
      expect {@provider.find_package(@name)}.to raise_error Chef::Exceptions::Package
    end

end

  describe "package name with available version (zsh-5.0.2)" do
    before do
      @name = 'zsh-5.0.2'
      @new_resource     = Chef::Resource::Package.new(@name)
      @current_resource = Chef::Resource::Package.new(@name)
      @provider = Chef::Provider::Package::Openbsd.new(@new_resource, @run_context)
      @provider.current_resource = @current_resource
      @provider.sqlports(:skip_installation => true)
      @info = @provider.find_package(@name)
    end

    it "should parse as a plain package with no version" do
      @info[:short_name].should     == 'zsh'
      @info[:short_version].should  == '5.0.2'
      @info[:pkgspec].should        == 'zsh-*'
      @info[:fullpkgname].should    == 'zsh-5.0.2'
      @info[:fullpkgpath].should    == 'shells/zsh'
    end

   it "should translate to a port path" do
      @provider.port_path.should == '/usr/ports/shells/zsh'
    end

    it "should have a valid repo candidate version" do
      @provider.repo_candidate_version.should == '5.0.2'
    end

    it "should have a valid port candidate version" do
      @provider.port_candidate_version.should == '5.0.2'
    end

  end

  describe "package with version and flavor (mutt-1.5.22p0v0-sasl)" do
    before do
      @name = 'mutt-1.5.22p0v0-sasl'
      @new_resource     = Chef::Resource::Package.new(@name)
      @current_resource = Chef::Resource::Package.new(@name)
      @provider = Chef::Provider::Package::Openbsd.new(@new_resource, @run_context)
      @provider.current_resource = @current_resource
      @provider.sqlports(:skip_installation => true)
      @info = @provider.find_package(@name)
    end

    it "should parse as a plain package with no version" do
      @info[:short_name].should     == 'mutt'
      @info[:short_version].should  == '1.5.22'
      @info[:pkgspec].should        == 'mutt-*'
      @info[:fullpkgname].should    == 'mutt-1.5.22p0v0-sasl'
      @info[:fullpkgpath].should    == 'mail/mutt/snapshot,sasl'
    end

   it "should translate to a port path" do
      @provider.port_path.should == '/usr/ports/mail/mutt/snapshot'
    end

    it "should have a valid repo candidate version" do
      @provider.repo_candidate_version.should == '1.5.22p0v0-sasl'
    end

    it "should have a valid port candidate version" do
      @provider.port_candidate_version.should == '1.5.22'
    end

  end

  describe "package with subpackage (gnome-extra)" do
    before do
      @name = 'gnome-extra'
      @new_resource     = Chef::Resource::Package.new(@name)
      @current_resource = Chef::Resource::Package.new(@name)
      @provider = Chef::Provider::Package::Openbsd.new(@new_resource, @run_context)
      @provider.current_resource = @current_resource
      @provider.sqlports(:skip_installation => true)
      @info = @provider.find_package(@name)
    end

    it "should parse as a plain package with no version" do
      @info[:short_name].should     == 'gnome-extra'
      @info[:short_version].should  == '3.10.2'
      @info[:pkgspec].should        == 'gnome-extra-*'
      @info[:fullpkgname].should    == 'gnome-extra-3.10.2'
      @info[:fullpkgpath].should    == 'meta/gnome,-extra'
    end

    it "should translate to a port path" do
      @provider.port_path.should == '/usr/ports/meta/gnome'
    end

    it "should have a valid repo candidate version" do
      @provider.repo_candidate_version.should == '3.10.2'
    end

    it "should have a valid port candidate version" do
      @provider.port_candidate_version.should == '3.10.2'
    end

  end

  describe "port path with 'main' subpackage (mail/gmime,-main)" do
    before do
      @name = 'mail/gmime,-main'
      @new_resource     = Chef::Resource::Package.new(@name)
      @current_resource = Chef::Resource::Package.new(@name)
      @provider = Chef::Provider::Package::Openbsd.new(@new_resource, @run_context)
      @provider.current_resource = @current_resource
      @provider.sqlports(:skip_installation => true)
      @info = @provider.find_package(@name)
    end

    it "should parse as a plain package with no version" do
      @info[:short_name].should     == 'gmime'
      @info[:short_version].should  == '2.6.19'
      @info[:pkgspec].should        == 'gmime-*'
      @info[:fullpkgname].should    == 'gmime-2.6.19'
      @info[:fullpkgpath].should    == 'mail/gmime,-main'
    end

    it "should translate to a port path" do
      @provider.port_path.should == '/usr/ports/mail/gmime'
    end

    it "should have a valid repo candidate version" do
      @provider.repo_candidate_version.should == '2.6.19'
    end

    it "should have a valid port candidate version" do
      @provider.port_candidate_version.should == '2.6.19'
    end

  end

  describe "port path with non-'main' subpackage (mail/gmime,-mono)" do
    before do
      @name = 'mail/gmime,-mono'
      @new_resource     = Chef::Resource::Package.new(@name)
      @current_resource = Chef::Resource::Package.new(@name)
      @provider = Chef::Provider::Package::Openbsd.new(@new_resource, @run_context)
      @provider.current_resource = @current_resource
      @provider.sqlports(:skip_installation => true)
      @info = @provider.find_package(@name)
    end

    it "should parse as a plain package with no version" do
      @info[:short_name].should     == 'gmime-sharp'
      @info[:short_version].should  == '2.6.19'
      @info[:pkgspec].should        == 'gmime-sharp-*'
      @info[:fullpkgname].should    == 'gmime-sharp-2.6.19'
      @info[:fullpkgpath].should    == @name
    end

    it "should translate to a port path" do
      @provider.port_path.should == '/usr/ports/mail/gmime'
    end

    it "should have a valid repo candidate version" do
      @provider.repo_candidate_version.should == '2.6.19'
    end

    it "should have a valid port candidate version" do
      @provider.port_candidate_version.should == '2.6.19'
    end

  end

  describe "package with a dash in the name, multiple major versions, and different package and port versions (php-zip-5.4.24)" do
    before do
      @name = 'php-zip-5.4.24'
      @new_resource     = Chef::Resource::Package.new(@name)
      @current_resource = Chef::Resource::Package.new(@name)
      @provider = Chef::Provider::Package::Openbsd.new(@new_resource, @run_context)
      @provider.current_resource = @current_resource
      @provider.sqlports(:skip_installation => true)
      @info = @provider.find_package(@name)
    end

    it "should parse as a plain package with no version" do
      @info[:short_name].should     == 'php-zip'
      @info[:short_version].should  == '5.4.24'
      @info[:pkgspec].should        == 'php-zip->=5.4,<5.5'
      @info[:fullpkgname].should    == 'php-zip-5.4.24'
      @info[:fullpkgpath].should    == 'lang/php/5.4,-zip'
    end

    it "should translate to a port path" do
      @provider.port_path.should == '/usr/ports/lang/php/5.4'
    end

    it "should have a valid repo candidate version" do
      @provider.repo_candidate_version.should == '5.4.24'
    end

    it "should have a valid port candidate version" do
      @provider.port_candidate_version.should =~ /5\.4\.\d*/
    end

  end

  describe "another package name to parse, for good measure (clamav)" do
    before do
      @name = 'clamav'
      @new_resource     = Chef::Resource::Package.new(@name)
      @current_resource = Chef::Resource::Package.new(@name)
      @provider = Chef::Provider::Package::Openbsd.new(@new_resource, @run_context)
      @provider.current_resource = @current_resource
      @provider.sqlports(:skip_installation => true)
      @info = @provider.find_package(@name)
    end

    it "should parse as a plain package with no version" do
      @info[:short_name].should     == 'clamav'
      @info[:short_version].should  == '0.98.1'
      @info[:pkgspec].should        == 'clamav-*'
      @info[:fullpkgname].should    == 'clamav-0.98.1'
      @info[:fullpkgpath].should    == 'security/clamav'
    end

    it "should translate to a port path" do
      @provider.port_path.should == '/usr/ports/security/clamav'
    end

    it "should have a valid repo candidate version" do
      @provider.repo_candidate_version.should == '0.98.1'
    end

    it "should have a valid port candidate version" do
      @provider.port_candidate_version.should == '0.98.4'
    end

  end

  describe "install a package" do
    before do
      @name = 'zzuf'
      @new_resource     = Chef::Resource::Package.new(@name)
      @current_resource = Chef::Resource::Package.new(@name)
      @provider = Chef::Provider::Package::Openbsd.new(@new_resource, @run_context)
      @provider.current_resource = @current_resource
      @provider.sqlports(:skip_installation => true)
      @info = @provider.find_package(@name)
    end
    it "should run the installation command" do
      expect(@provider).to receive(:shell_out!).with(
        "pkg_add -r #{@name}",
        :env=>{
          "PACKAGESITE" => "http://ftp.eu.openbsd.org/pub/OpenBSD/5.5/packages/amd64/",
          "LC_ALL" => nil
        }
      ) {OpenStruct.new :status => true}
      @provider.install_package(@name, nil)
    end
  end

  describe "delete a package" do
    before do
      @name = 'sqlports'
      @new_resource     = Chef::Resource::Package.new(@name)
      @current_resource = Chef::Resource::Package.new(@name)
      @provider = Chef::Provider::Package::Openbsd.new(@new_resource, @run_context)
      @provider.current_resource = @current_resource
      @provider.sqlports(:skip_installation => true)
      @info = @provider.find_package(@name)
    end
    it "should run the command to delete the installed package" do
      expect(@provider).to receive(:shell_out!).with(
        "pkg_delete sqlports", :env=>nil
      ) {OpenStruct.new :status => true}
      @provider.remove_package(@name, nil)
    end
  end

end

