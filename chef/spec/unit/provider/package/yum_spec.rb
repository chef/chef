#
# Author:: Adam Jacob (<adam@opscode.com>)
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

describe Chef::Provider::Package::Yum do
  before(:each) do
    @node = Chef::Node.new
    @run_context = Chef::RunContext.new(@node, {})
    @new_resource = Chef::Resource::Package.new('cups')
    @status = mock("Status", :exitstatus => 0)
    @yum_cache = mock(
      'Chef::Provider::Yum::YumCache',
      :reload_from_cache => true,
      :flush => true,
      :installed_version => "1.2.4-11.18.el5",
      :candidate_version => "1.2.4-11.18.el5_2.3",
      :version_available? => true
    )
    Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
    @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
    @stderr = StringIO.new
    @pid = mock("PID")
  end

  describe "when loading the current system state" do

    it "should create a current resource with the name of the new_resource" do
      @provider.load_current_resource
      @provider.current_resource.name.should == "cups"
    end

    it "should set the current resources package name to the new resources package name" do
      @provider.load_current_resource
      @provider.current_resource.package_name.should == "cups"
    end

    it "should set the installed version to nil on the current resource if no installed package" do
      @yum_cache.stub!(:installed_version).and_return(nil)
      @provider.load_current_resource
      @provider.current_resource.version.should be_nil
    end

    it "should set the installed version if yum has one" do
      @provider.load_current_resource
      @provider.current_resource.version.should == "1.2.4-11.18.el5"
    end

    it "should set the candidate version if yum info has one" do
      @provider.load_current_resource
      @provider.candidate_version.should eql("1.2.4-11.18.el5_2.3")
    end

    it "should return the current resouce" do
      @provider.load_current_resource.should eql(@provider.current_resource)
    end

    describe "when arch in package_name" do
      it "should set the arch if no existing package_name is found and new_package_name+new_arch is available" do
        @new_resource = Chef::Resource::YumPackage.new('testing.noarch')
        @yum_cache = mock(
          'Chef::Provider::Yum::YumCache'
        )
        @yum_cache.stub!(:installed_version) do |package_name, arch|
          # nothing installed for package_name/new_package_name
          nil 
        end
        @yum_cache.stub!(:candidate_version) do |package_name, arch|
          if package_name == "testing.noarch" || package_name == "testing.more.noarch"
            nil
          # candidate for new_package_name
          elsif package_name == "testing" || package_name == "testing.more"
            "1.1"
          end
        end
        Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
        @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
        @provider.load_current_resource
        @provider.new_resource.package_name.should == "testing"
        @provider.new_resource.arch.should == "noarch"
        @provider.arch.should == "noarch"

        @new_resource = Chef::Resource::YumPackage.new('testing.more.noarch')
        @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
        @provider.load_current_resource
        @provider.new_resource.package_name.should == "testing.more"
        @provider.new_resource.arch.should == "noarch"
        @provider.arch.should == "noarch"
      end

      it "should not set the arch when an existing package_name is found" do
        @new_resource = Chef::Resource::YumPackage.new('testing.beta3')
        @yum_cache = mock(
          'Chef::Provider::Yum::YumCache'
        )
        @yum_cache.stub!(:installed_version) do |package_name, arch|
          # installed for package_name
          if package_name == "testing.beta3" || package_name == "testing.beta3.more"
            "1.1"
          elsif package_name == "testing" || package_name = "testing.beta3"
            nil
          end
        end
        @yum_cache.stub!(:candidate_version) do |package_name, arch|
          # no candidate for package_name/new_package_name
          nil
        end
        Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
        @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
        @provider.load_current_resource
        @provider.new_resource.package_name.should == "testing.beta3"
        @provider.new_resource.arch.should == nil 
        @provider.arch.should == nil 

        @new_resource = Chef::Resource::YumPackage.new('testing.beta3.more')
        @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
        @provider.load_current_resource
        @provider.new_resource.package_name.should == "testing.beta3.more"
        @provider.new_resource.arch.should == nil 
        @provider.arch.should == nil 
      end

      it "should not set the arch when no existing package_name or new_package_name+new_arch is found" do
        @new_resource = Chef::Resource::YumPackage.new('testing.beta3')
        @yum_cache = mock(
          'Chef::Provider::Yum::YumCache'
        )
        @yum_cache.stub!(:installed_version) do |package_name, arch|
          # nothing installed for package_name/new_package_name
          nil
        end
        @yum_cache.stub!(:candidate_version) do |package_name, arch|
          # no candidate for package_name/new_package_name
          nil
        end
        Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
        @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
        @provider.load_current_resource
        @provider.new_resource.package_name.should == "testing.beta3"
        @provider.new_resource.arch.should == nil 
        @provider.arch.should == nil 

        @new_resource = Chef::Resource::YumPackage.new('testing.beta3.more')
        @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
        @provider.load_current_resource
        @provider.new_resource.package_name.should == "testing.beta3.more"
        @provider.new_resource.arch.should == nil 
        @provider.arch.should == nil 
      end

      it "should ensure it doesn't clobber an existing arch if passed" do
        @new_resource = Chef::Resource::YumPackage.new('testing.i386')
        @new_resource.arch("x86_64")
        @yum_cache = mock(
          'Chef::Provider::Yum::YumCache'
        )
         @yum_cache.stub!(:installed_version) do |package_name, arch|
           # nothing installed for package_name/new_package_name
         nil 
        end
        @yum_cache.stub!(:candidate_version) do |package_name, arch|
          if package_name == "testing.noarch"
            nil
          # candidate for new_package_name
          elsif package_name == "testing"
            "1.1"
          end
        end
        Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
        @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
        @provider.load_current_resource
        @provider.new_resource.package_name.should == "testing.i386"
        @provider.new_resource.arch.should == "x86_64" 
      end
    end
  end

  describe "when installing a package" do
    it "should run yum install with the package name and version" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y install emacs-1.0"
      })
      @provider.install_package("emacs", "1.0")
    end

    it "should run yum localinstall if given a path to an rpm" do
      @new_resource.stub!(:source).and_return("/tmp/emacs-21.4-20.el5.i386.rpm")
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y localinstall /tmp/emacs-21.4-20.el5.i386.rpm"
      })
      @provider.install_package("emacs", "21.4-20.el5")
    end

    it "should run yum install with the package name, version and arch" do
      @new_resource.stub!(:arch).and_return("i386")
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y install emacs-21.4-20.el5.i386"
      })
      @provider.install_package("emacs", "21.4-20.el5")
    end

    it "installs the package with the options given in the resource" do
      @provider.candidate_version = '11'
      @new_resource.stub!(:options).and_return("--disablerepo epmd")
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y --disablerepo epmd install cups-11"
      })
      @provider.install_package(@new_resource.name, @provider.candidate_version)
    end

    it "should fail if the package is not available" do
      @yum_cache = mock(
        'Chef::Provider::Yum::YumCache',
        :reload_from_cache => true,
        :flush => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.18.el5_2.3",
        :version_available? => nil
      )
      Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      lambda { @provider.install_package("lolcats", "0.99") }.should raise_error(ArgumentError)
    end
  end

  describe "when upgrading a package" do
    it "should run yum update if the package is installed and no version is given" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y update cups"
      })
      @provider.upgrade_package(@new_resource.name, nil)
    end

    it "should run yum update with arch if the package is installed and no version is given" do
      @new_resource.stub!(:arch).and_return("i386")
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y update cups.i386"
      })
      @provider.upgrade_package(@new_resource.name, nil)
    end

    it "should run yum install if the package is installed and a version is given" do
      @provider.candidate_version = '11'
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y install cups-11"
      })
      @provider.upgrade_package(@new_resource.name, @provider.candidate_version)
    end

    it "should run yum install if the package is not installed" do
      @current_resource = Chef::Resource::Package.new('cups')
      @provider.candidate_version = '11'
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y install cups-11"
      })
      @provider.upgrade_package(@new_resource.name, @provider.candidate_version)
    end
  end

  describe "when removing a package" do
    it "should run yum remove with the package name" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y remove emacs-1.0"
      })
      @provider.remove_package("emacs", "1.0")
    end

    it "should run yum remove with the package name and arch" do
      @new_resource.stub!(:arch).and_return("x86_64")
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y remove emacs-1.0.x86_64"
      })
      @provider.remove_package("emacs", "1.0")
    end
  end

  describe "when purging a package" do
    it "should run yum remove with the package name" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y remove emacs-1.0"
      })
      @provider.purge_package("emacs", "1.0")
    end
  end

end

describe Chef::Provider::Package::Yum::RPMUtils do
  describe "version_parse" do
    before do
      @rpmutils = Chef::Provider::Package::Yum::RPMUtils
    end

    it "parses known good epoch strings" do
      [ 
        [ "0:3.3", [ 0, "3.3", nil ] ],
        [ "9:1.7.3", [ 9, "1.7.3", nil ] ],
        [ "15:20020927", [ 15, "20020927", nil ] ]
      ].each do |x, y|
        @rpmutils.version_parse(x).should == y
      end
    end

    it "parses strange epoch strings" do
      [ 
        [ ":3.3", [ 0, "3.3", nil ] ],
        [ "-1:1.7.3", [ nil, "", "1:1.7.3" ] ],
        [ "-:20020927", [ nil, "", ":20020927" ] ]
      ].each do |x, y|
        @rpmutils.version_parse(x).should == y
      end
    end

    it "parses known good version strings" do
      [ 
        [ "3.3", [ nil, "3.3", nil ] ],
        [ "1.7.3", [ nil, "1.7.3", nil ] ],
        [ "20020927", [ nil, "20020927", nil ] ]
      ].each do |x, y|
        @rpmutils.version_parse(x).should == y
      end
    end

    it "parses strange version strings" do
      [ 
        [ "3..3", [ nil, "3..3", nil ] ],
        [ "0001.7.3", [ nil, "0001.7.3", nil ] ],
        [ "20020927,3", [ nil, "20020927,3", nil ] ]
      ].each do |x, y|
        @rpmutils.version_parse(x).should == y
      end
    end

    it "parses known good version release strings" do
      [ 
        [ "3.3-0.pre3.1.60.el5_5.1", [ nil, "3.3", "0.pre3.1.60.el5_5.1" ] ],
        [ "1.7.3-1jpp.2.el5", [ nil, "1.7.3", "1jpp.2.el5" ] ],
        [ "20020927-46.el5", [ nil, "20020927", "46.el5" ] ]
      ].each do |x, y|
        @rpmutils.version_parse(x).should == y
      end
    end

    it "parses strange version release strings" do
      [ 
        [ "3.3-", [ nil, "3.3", nil ] ],
        [ "-1jpp.2.el5", [ nil, "", "1jpp.2.el5" ] ],
        [ "-0020020927-46.el5", [ nil, "-0020020927", "46.el5" ] ]
      ].each do |x, y|
        @rpmutils.version_parse(x).should == y
      end
    end
  end

  describe "rpmvercmp" do
    before do
      @rpmutils = Chef::Provider::Package::Yum::RPMUtils
    end

    it "standard comparison examples" do
      [ 
        # numeric
        [ "0.0.2", "0.0.1", 1 ],
        [ "0.2.0", "0.1.0", 1 ],
        [ "2.0.0", "1.0.0", 1 ],
        [ "0.0.1", "0.0.1", 0 ],
        [ "0.0.1", "0.0.2", -1 ],
        [ "0.1.0", "0.2.0", -1 ],
        [ "1.0.0", "2.0.0", -1 ],
        # alpha
        [ "bb", "aa", 1 ],
        [ "ab", "aa", 1 ],
        [ "aa", "aa", 0 ],
        [ "aa", "bb", -1 ],
        [ "aa", "ab", -1 ],
        [ "BB", "AA", 1 ],
        [ "AA", "AA", 0 ],
        [ "AA", "BB", -1 ],
        [ "aa", "AA", 1 ],
        [ "AA", "aa", -1 ],
        # alphanumeric
        [ "0.0.1b", "0.0.1a", 1 ],
        [ "0.1b.0", "0.1a.0", 1 ],
        [ "1b.0.0", "1a.0.0", 1 ],
        [ "0.0.1a", "0.0.1a", 0 ],
        [ "0.0.1a", "0.0.1b", -1 ],
        [ "0.1a.0", "0.1b.0", -1 ],
        [ "1a.0.0", "1b.0.0", -1 ],
        # alphanumeric against alphanumeric
        [ "0.0.1", "0.0.a", 1 ],
        [ "0.1.0", "0.a.0", 1 ],
        [ "1.0.0", "a.0.0", 1 ],
        [ "0.0.a", "0.0.a", 0 ],
        [ "0.0.a", "0.0.1", -1 ],
        [ "0.a.0", "0.1.0", -1 ],
        [ "a.0.0", "1.0.0", -1 ],
        # alphanumeric against numeric
        [ "0.0.2", "0.0.1a", 1 ],
        [ "0.0.2a", "0.0.1", 1 ],
        [ "0.0.1", "0.0.2a", -1 ],
        [ "0.0.1a", "0.0.2", -1 ],
        # length
        [ "0.0.1aa", "0.0.1a", 1 ],
        [ "0.0.1aa", "0.0.1aa", 0 ],
        [ "0.0.1a", "0.0.1aa", -1 ],
     ].each do |x, y, result|
        @rpmutils.rpmvercmp(x,y).should == result
      end
    end

    it "strange comparison examples" do
      [
        [ "2,0,0", "1.0.0", 1 ],
        [ "0.0.1", "0,0.1", 0 ],
        [ "1.0.0", "2,0,0", -1 ],
        [ "002.0.0", "001.0.0", 1 ],
        [ "001..0.1", "001..0.0", 1 ],
        [ "-001..1", "-001..0", 1 ],
        [ "1.0.1", nil, 1 ],
        [ nil, nil, 0 ],
        [ nil, "1.0.1", -1 ],
        [ "1.0.1", "", 1 ],
        [ "", "", 0 ],
        [ "", "1.0.1", -1 ]
     ].each do |x, y, result|
        @rpmutils.rpmvercmp(x,y).should == result
      end
    end

    it "tests isalnum good input" do
      [ 'a', 'z', 'A', 'Z', '0', '9' ].each do |t|
        @rpmutils.isalnum(t).should == true
      end
    end

    it "tests isalnum bad input" do
      [ '-', '.', '!', '^', ':', '_' ].each do |t|
        @rpmutils.isalnum(t).should == false 
      end
    end

    it "tests isalpha good input" do
      [ 'a', 'z', 'A', 'Z', ].each do |t|
        @rpmutils.isalpha(t).should == true
      end
    end

    it "tests isalpha bad input" do
      [ '0', '9', '-', '.', '!', '^', ':', '_' ].each do |t|
        @rpmutils.isalpha(t).should == false 
      end
    end

    it "tests isdigit good input" do
      [ '0', '9', ].each do |t|
        @rpmutils.isdigit(t).should == true
      end
    end

    it "tests isdigit bad input" do
      [ 'A', 'z', '-', '.', '!', '^', ':', '_' ].each do |t|
        @rpmutils.isdigit(t).should == false 
      end
    end
  end

end

describe Chef::Provider::Package::Yum::RPMPackage do
  describe "new - with parsing" do
    before do
      @rpm = Chef::Provider::Package::Yum::RPMPackage.new("testing", "1:1.6.5-9.36.el5", "x86_64")
    end

    it "should expose nevra (name-epoch-version-release-arch) available" do
      @rpm.name.should == "testing"
      @rpm.epoch.should == 1
      @rpm.version.should == "1.6.5"
      @rpm.release.should == "9.36.el5"
      @rpm.arch.should == "x86_64"

      @rpm.nevra.should == "testing-1:1.6.5-9.36.el5.x86_64"
    end

    it "should output a version-release string" do
      @rpm.to_s.should == "1.6.5-9.36.el5"
    end
  end

  describe "new - no parsing" do
    before do
      @rpm = Chef::Provider::Package::Yum::RPMPackage.new("testing", "1", "1.6.5", "9.36.el5", "x86_64")
    end

    it "should expose nevra (name-epoch-version-release-arch) available" do
      @rpm.name.should == "testing"
      @rpm.epoch.should == 1
      @rpm.version.should == "1.6.5"
      @rpm.release.should == "9.36.el5"
      @rpm.arch.should == "x86_64"

      @rpm.nevra.should == "testing-1:1.6.5-9.36.el5.x86_64"
    end

    it "should output a version-release string" do
      @rpm.to_s.should == "1.6.5-9.36.el5"
    end
  end

  it "should raise an error unless passed 3 or 5 args" do
    lambda {
      Chef::Provider::Package::Yum::RPMPackage.new()
    }.should raise_error(ArgumentError)
    lambda {
      Chef::Provider::Package::Yum::RPMPackage.new("testing", "1:1.6.5-9.36.el5", "x86_64", "extra")
    }.should raise_error(ArgumentError)
    lambda {
      Chef::Provider::Package::Yum::RPMPackage.new("testing", "1:1.6.5-9.36.el5", "x86_64", "extra", "extra", "extra")
    }.should raise_error(ArgumentError)
  end

  # thanks version_class_spec.rb!
  describe "<=>" do
    it "should sort based on complete epoch-version-release data" do
      [
        # smaller, larger
        [ "0:1.6.5-9.36.el5", 
          "1:1.6.5-9.36.el5" ],
        [ "0:2.3-15.el5", 
          "0:3.3-15.el5" ],
        [ "0:alpha9.8-27.2", 
          "0:beta9.8-27.2" ],
        [ "0:0.09-14jpp.3", 
          "0:0.09-15jpp.3" ],
        [ "0:0.9.0-0.6.20110211.el5", 
          "0:0.9.0-0.6.20120211.el5" ],
        [ "0:1.9.1-4.el5", 
          "0:1.9.1-5.el5" ],
        [ "0:1.4.10-7.20090624svn.el5", 
          "0:1.4.10-7.20090625svn.el5" ],
        [ "0:2.3.4-2.el5", 
          "0:2.3.4-2.el6" ]
      ].each do |smaller, larger|
        sm = Chef::Provider::Package::Yum::RPMPackage.new("test-package", smaller, "x86_64")
        lg = Chef::Provider::Package::Yum::RPMPackage.new("test-package", larger, "x86_64")
        sm.should be < lg
        lg.should be > sm
        sm.should_not == lg
      end
    end

    it "should sort based on partial epoch-version-release data" do
      [
        # smaller, larger
        [ ":1.6.5-9.36.el5", 
          "1:1.6.5-9.36.el5" ],
        [ "2.3-15.el5", 
          "3.3-15.el5" ],
        [ "alpha9.8", 
          "beta9.8" ],
        [ "14jpp", 
          "15jpp" ],
        [ "0.9.0-0.6", 
          "0.9.0-0.7" ],
        [ "0:1.9", 
          "3:1.9" ],
        [ "2.3-2.el5", 
          "2.3-2.el6" ]
      ].each do |smaller, larger|
        sm = Chef::Provider::Package::Yum::RPMPackage.new("test-package", smaller, "x86_64")
        lg = Chef::Provider::Package::Yum::RPMPackage.new("test-package", larger, "x86_64")
        sm.should be < lg
        lg.should be > sm
        sm.should_not == lg
      end
    end

    it "should verify equality of complete epoch-version-release data" do
      [
        [ "0:1.6.5-9.36.el5", 
          "0:1.6.5-9.36.el5" ],
        [ "0:2.3-15.el5", 
          "0:2.3-15.el5" ],
        [ "0:alpha9.8-27.2", 
          "0:alpha9.8-27.2" ]
      ].each do |smaller, larger|
        sm = Chef::Provider::Package::Yum::RPMPackage.new("test-package", smaller, "x86_64")
        lg = Chef::Provider::Package::Yum::RPMPackage.new("test-package", larger, "x86_64")
        sm.should be == lg
      end
    end

    it "should verify equality of partial epoch-version-release data" do
      [
        [ ":1.6.5-9.36.el5", 
          "0:1.6.5-9.36.el5" ],
        [ "2.3-15.el5", 
          "2.3-15.el5" ],
        [ "alpha9.8-3", 
          "alpha9.8-3" ]
      ].each do |smaller, larger|
        sm = Chef::Provider::Package::Yum::RPMPackage.new("test-package", smaller, "x86_64")
        lg = Chef::Provider::Package::Yum::RPMPackage.new("test-package", larger, "x86_64")
        sm.should be == lg
      end
    end

    it "should sort alphabetically based on package name" do
      [
        [ "a-test", 
          "b-test" ],
        [ "B-test", 
          "a-test" ],
        [ "A-test", 
          "B-test" ],
        [ "Aa-test", 
          "aA-test" ],
        [ "1test", 
          "2test" ],
      ].each do |smaller, larger|
        sm = Chef::Provider::Package::Yum::RPMPackage.new(smaller, "0:0.0.1-1", "x86_64")
        lg = Chef::Provider::Package::Yum::RPMPackage.new(larger, "0:0.0.1-1", "x86_64")
        sm.should be < lg
        lg.should be > sm
        sm.should_not == lg
      end
    end

    it "should sort alphabetically based on package arch" do
      [
        [ "i386", 
          "x86_64" ],
        [ "i386", 
          "noarch" ],
        [ "noarch", 
          "x86_64" ],
      ].each do |smaller, larger|
        sm = Chef::Provider::Package::Yum::RPMPackage.new("test-package", "0:0.0.1-1", smaller)
        lg = Chef::Provider::Package::Yum::RPMPackage.new("test-package", "0:0.0.1-1", larger)
        sm.should be < lg
        lg.should be > sm
        sm.should_not == lg
      end
    end
  end

end

# thanks resource_collection_spec.rb!
describe Chef::Provider::Package::Yum::RPMDb do
  before(:each) do
    @rpmdb = Chef::Provider::Package::Yum::RPMDb.new
    @rpm_w = Chef::Provider::Package::Yum::RPMPackage.new("test-package-a", "0:1.6.5-9.36.el5", "i386")
    @rpm_x = Chef::Provider::Package::Yum::RPMPackage.new("test-package-a", "0:1.6.5-9.36.el5", "x86_64")
    @rpm_y = Chef::Provider::Package::Yum::RPMPackage.new("test-package-a", "1:1.6.5-9.36.el5", "x86_64")
    @rpm_z = Chef::Provider::Package::Yum::RPMPackage.new("test-package-b", "0:1.6.5-9.36.el5", "noarch")
    @rpm_z_mirror = Chef::Provider::Package::Yum::RPMPackage.new("test-package-b", "0:1.6.5-9.36.el5", "noarch")
  end

  describe "initialize" do
    it "should return a Chef::Provider::Package::Yum::RPMDb object" do
      @rpmdb.should be_kind_of(Chef::Provider::Package::Yum::RPMDb)
    end
  end

  describe "push" do
    it "should accept an RPMPackage object through pushing" do
      lambda { @rpmdb.push(@rpm_w) }.should_not raise_error
    end

    it "should accept multiple RPMPackage object through pushing" do
      lambda { @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z) }.should_not raise_error
    end

    it "should only accept an RPMPackage object" do
      lambda { @rpmdb.push(@rpm_w) }.should_not raise_error
      lambda { @rpmdb.push("string") }.should raise_error
    end
  end

  describe "<<" do
    it "should accept an RPMPackage object through the << operator" do
      lambda { @rpmdb << @rpm_w }.should_not raise_error
    end
  end

  describe "lookup" do
    it "should return an Array of RPMPackage objects by index" do
      @rpmdb << @rpm_w 
      @rpmdb.lookup("test-package-a").should be_kind_of(Array)
    end
  end

  describe "[]" do
    it "should return an Array of RPMPackage objects though the [index] operator" do
      @rpmdb << @rpm_w 
      @rpmdb["test-package-a"].should be_kind_of(Array)
    end
  end

  it "should return an Array of 3 RPMPackage objects" do
    @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
    @rpmdb["test-package-a"].size.should be == 3
  end

  it "should have a total of 2 packages in the RPMDb" do
    @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
    @rpmdb.size.should be == 2
    @rpmdb.length.should be == 2
  end

  it "should clear the RPMDb" do
    @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
    @rpmdb.clear
    @rpmdb.size.should be == 0
  end

  it "should keep the Array unique when a duplicate is pushed" do
    @rpmdb.push(@rpm_z, @rpm_z_mirror)
    @rpmdb["test-package-b"].size.should be == 1
  end

  it "should return an Array of RPMPackage objects sorted from newest to oldest" do
    @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
    @rpmdb["test-package-a"][0].should be == @rpm_y
    @rpmdb["test-package-a"][1].should be == @rpm_x
    @rpmdb["test-package-a"][2].should be == @rpm_w
  end

end

describe Chef::Provider::Package::Yum::YumCache do
  # allow for the reset of a Singleton
  # thanks to Ian White (http://blog.ardes.com/2006/12/11/testing-singletons-with-ruby)
  class << Chef::Provider::Package::Yum::YumCache
    def reset_instance
      Singleton.send :__init__, self
      self
    end
  end

  before(:each) do
    yum_dump_good_output = <<EOF
zip 0 2.31 2.el5 x86_64 i
zisofs-tools 0 1.0.6 3.2.2 x86_64 a
zlib 0 1.2.3 3 x86_64 i
zlib 0 1.2.3 3 i386 i
zlib-devel 0 1.2.3 3 i386 a
zlib-devel 0 1.2.3 3 x86_64 i
znc 0 0.098 1.el5 x86_64 a
znc-devel 0 0.098 1.el5 i386 a
znc-devel 0 0.098 1.el5 x86_64 a
znc-extra 0 0.098 1.el5 x86_64 a
znc-modtcl 0 0.098 1.el5 x86_64 a
EOF

    yum_dump_bad_output_separators = <<EOF
zip 0 2.31 2.el5 x86_64 i
zlib 0 1.2.3 3 x86_64 i bad
zlib-devel 0 1.2.3 3 i386 a
bad zlib-devel 0 1.2.3 3 x86_64 i
znc-modtcl 0 0.098 1.el5 x86_64 a bad
EOF

    yum_dump_bad_output_type = <<EOF
zip 0 2.31 2.el5 x86_64 i
zlib 0 1.2.3 3 x86_64 c
zlib-devel 0 1.2.3 3 i386 a
zlib-devel 0 1.2.3 3 x86_64 bad
znc-modtcl 0 0.098 1.el5 x86_64 a
EOF

    yum_dump_error = <<EOF
yum-dump Config Error: File contains no section headers.
file: file://///etc/yum.repos.d/CentOS-Base.repo, line: 12
'qeqwewe\n'
EOF

    @status = mock("Status", :exitstatus => 0)
    @status_bad = mock("Status", :exitstatus => 1)
    @stdin = mock("STDIN", :nil_object => true)
    @stdout = mock("STDOUT", :nil_object => true)
    @stdout_good = yum_dump_good_output.split("\n")
    @stdout_bad_type = yum_dump_bad_output_type.split("\n")
    @stdout_bad_separators = yum_dump_bad_output_separators.split("\n")
    @stderr = mock("STDERR", :nil_object => true)
    @stderr.stub!(:readlines).and_return(yum_dump_error.split("\n"))
    @pid = mock("PID", :nil_object => true)

    # new singleton each time
    Chef::Provider::Package::Yum::YumCache.reset_instance
    @yc = Chef::Provider::Package::Yum::YumCache.instance
    # load valid data
    @yc.stub!(:popen4).and_yield(@pid, @stdin, @stdout_good, @stderr).and_return(@status)
  end

  describe "initialize" do
    it "should return a Chef::Provider::Package::Yum::YumCache object" do
      @yc.should be_kind_of(Chef::Provider::Package::Yum::YumCache)
    end

    it "should register load_data and flush for start and end of Chef::Client runs" do
      Chef::Provider::Package::Yum::YumCache.reset_instance
      Chef::Client.should_receive(:when_run_starts) do |&b|
        b.should_not be_nil
      end
      @yc = Chef::Provider::Package::Yum::YumCache.instance
    end
  end

  describe "installed" do
    it "should return a Chef::Provider::Package::Yum::RPMDb object" do
      @yc.installed.should be_kind_of(Chef::Provider::Package::Yum::RPMDb)
    end

    it "should implicitly call load_data only once after being instantiated" do
      @yc.should_receive(:load_data).once
      @yc.installed
      @yc.flush
      @yc.installed
    end

    it "should have a number of packages already loaded" do
      @yc.installed.size.should be == 3
    end
  end

  describe "available" do
    it "should return a Chef::Provider::Package::Yum::RPMDb object" do
      @yc.available.should be_kind_of(Chef::Provider::Package::Yum::RPMDb)
    end

    it "should implicitly call load_data only once after being instantiated" do
      @yc.should_receive(:load_data).once
      @yc.available
      @yc.flush
      @yc.available
    end

    it "should have a number of packages already loaded" do
      @yc.available.size.should be == 6 
    end
  end

  describe "load_data" do
    it "should run yum-dump.py using the system python" do
      @yc.should_receive(:popen4).with(%r{^/usr/bin/python .*/yum-dump.py$}, :waitlast=>true)
      @yc.load_data
    end

    it "should run yum-dump.py with the cache flag using the system python" do
      @yc.should_receive(:popen4).with(%r{^/usr/bin/python .*/yum-dump.py -C$}, :waitlast=>true)
      @yc.load_data(true)
    end

    it "should create RPMPackage objects from the parsed data" do
      @yc.flush
      @yc.load_data
      @yc.installed["zip"].first.should be_kind_of(Chef::Provider::Package::Yum::RPMPackage)
    end

    it "should warn about invalid data with too many separators" do
      @yc.stub!(:popen4).and_yield(@pid, @stdin, @stdout_bad_separators, @stderr).and_return(@status)
      Chef::Log.should_receive(:warn).exactly(3).times.with(%r{Problem parsing})
      @yc.flush
      @yc.load_data
      @yc.installed.size.should be == 1
      @yc.available.size.should be == 1
    end

    it "should warn about invalid data with an incorrect type" do
      @yc.stub!(:popen4).and_yield(@pid, @stdin, @stdout_bad_type, @stderr).and_return(@status)
      Chef::Log.should_receive(:warn).exactly(2).times.with(%r{Skipping line})
      @yc.flush
      @yc.load_data
      @yc.installed.size.should be == 1
      @yc.available.size.should be == 2
    end

    it "should warn about no output from yum-dump.py" do
      @yc.stub!(:popen4).and_yield(@pid, @stdin, [], @stderr).and_return(@status)
      Chef::Log.should_receive(:warn).exactly(1).times.with(%r{no output from yum-dump.py})
      @yc.flush
      @yc.load_data
    end

    it "should raise exception yum-dump.py exits with a non zero status" do
      @yc.stub!(:popen4).and_yield(@pid, @stdin, [], @stderr).and_return(@status_bad)
      @yc.flush
      lambda { @yc.load_data }.should raise_error(Chef::Exceptions::Package, %r{CentOS-Base.repo, line: 12})
    end

    describe "new_instance" do
      before(:each) do
        @yc.load_data
      end

      it "should always set new_instance to false so load_data won't be triggered again" do
        @yc.should_not_receive(:load_data)
        @yc.available
        @yc.installed
      end
    end
  end

  describe "reload" do
    it "should flush and load data, not using cache" do
      @yc.should_receive(:flush)
      @yc.should_receive(:load_data).with(false)
      @yc.reload
    end
  end

  describe "reload_from_cache" do
    it "should flush and load data, using cache" do
      @yc.should_receive(:flush)
      @yc.should_receive(:load_data).with(true)
      @yc.reload_from_cache
    end
  end

  describe "version" do
    it "should return version-release for matching package regardless of arch" do
      @yc.version("zip", @yc.installed, "x86_64").should be == "2.31-2.el5"
      @yc.version("zip", @yc.installed, nil).should be == "2.31-2.el5"
    end

    it "should return version-release for matching package and arch" do
      @yc.version("zisofs-tools", @yc.available, "x86_64").should be == "1.0.6-3.2.2"
      @yc.version("zisofs-tools", @yc.available, "i386").should be == nil
    end

    it "should return nil for an unmatched package" do
      @yc.version(nil, nil, nil).should be == nil 
      @yc.version("test1", nil, nil).should be == nil 
      @yc.version("test1", @yc.available, nil).should be == nil 
      @yc.version("test2", @yc.available, "x86_64").should be == nil 
    end
  end

  describe "installed_version" do
    it "should take one or two arguments" do
      lambda { @yc.installed_version("zip") }.should_not raise_error(ArgumentError)
      lambda { @yc.installed_version("zip", "i386") }.should_not raise_error(ArgumentError)
      lambda { @yc.installed_version("zip", "i386", "extra") }.should raise_error(ArgumentError)
    end

    it "should call version with the installed packages RPMDb" do
      @yc.installed_version("zip", "x86_64").should be == "2.31-2.el5"
      @yc.installed_version("zip", nil).should be == "2.31-2.el5"
      @yc.installed_version("zip", "i386").should be == nil
      @yc.installed_version("fake", nil).should be == nil
    end
  end

  describe "available_version" do
    it "should take one or two arguments" do
      lambda { @yc.available_version("zisofs-tools") }.should_not raise_error(ArgumentError)
      lambda { @yc.available_version("zisofs-tools", "i386") }.should_not raise_error(ArgumentError)
      lambda { @yc.available_version("zisofs-tools", "i386", "extra") }.should raise_error(ArgumentError)
    end

    it "should call version with the available packages RPMDb" do
      @yc.available_version("zisofs-tools", "x86_64").should be == "1.0.6-3.2.2"
      @yc.available_version("zisofs-tools", nil).should be == "1.0.6-3.2.2"
      @yc.available_version("zisofs-tools", "i386").should be == nil
      @yc.available_version("fake", nil).should be == nil
    end
  end

  describe "flush" do
    it "should empty the installed and available packages RPMDb" do
      @yc.installed.size.should be == 3
      @yc.available.size.should be == 6
      @yc.flush
      @yc.installed.size.should be == 0 
      @yc.available.size.should be == 0
    end
  end

end
