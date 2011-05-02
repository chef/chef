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
      :refresh => true,
      :reload => true,
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
  end

  describe "when installing a package" do
    it "should run yum install with the package name and version" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y  install emacs-1.0"
      })
      @provider.install_package("emacs", "1.0")
    end

    it "should run yum localinstall if given a path to an rpm" do
      @new_resource.stub!(:source).and_return("/tmp/emacs-21.4-20.el5.i386.rpm")
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y  localinstall /tmp/emacs-21.4-20.el5.i386.rpm"
      })
      @provider.install_package("emacs", "21.4-20.el5")
    end

    it "should run yum install with the package name, version and arch" do
      @new_resource.stub!(:arch).and_return("i386")
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y  install emacs-21.4-20.el5.i386"
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
        :refresh => true,
        :reload => true,
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
        :command => "yum -d0 -e0 -y  update cups"
      })
      @provider.upgrade_package(@new_resource.name, nil)
    end

    it "should run yum update with arch if the package is installed and no version is given" do
      @new_resource.stub!(:arch).and_return("i386")
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y  update cups.i386"
      })
      @provider.upgrade_package(@new_resource.name, nil)
    end

    it "should run yum install if the package is installed and a version is given" do
      @provider.candidate_version = '11'
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y  install cups-11"
      })
      @provider.upgrade_package(@new_resource.name, @provider.candidate_version)
    end

    it "should run yum install if the package is not installed" do
      @current_resource = Chef::Resource::Package.new('cups')
      @provider.candidate_version = '11'
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y  install cups-11"
      })
      @provider.upgrade_package(@new_resource.name, @provider.candidate_version)
    end
  end

  describe "when removing a package" do
    it "should run yum remove with the package name" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y  remove emacs-1.0"
      })
      @provider.remove_package("emacs", "1.0")
    end

    it "should run yum remove with the package name and arch" do
      @new_resource.stub!(:arch).and_return("x86_64")
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y  remove emacs-1.0.x86_64"
      })
      @provider.remove_package("emacs", "1.0")
    end
  end

  describe "when purging a package" do
    it "should run yum remove with the package name" do
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y  remove emacs-1.0"
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
        [ "0.0.1a", "0.0.1aa", -1 ]
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
        [ "-001..1", "-001..0", 1 ]
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
  describe "new" do
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
        sm = Chef::Provider::Package::Yum::RPMPackage.new("smaller", smaller, "x86_64")
        lg = Chef::Provider::Package::Yum::RPMPackage.new("larger", larger, "x86_64")
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
        sm = Chef::Provider::Package::Yum::RPMPackage.new("smaller", smaller, "x86_64")
        lg = Chef::Provider::Package::Yum::RPMPackage.new("larger", larger, "x86_64")
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
        sm = Chef::Provider::Package::Yum::RPMPackage.new("smaller", smaller, "x86_64")
        lg = Chef::Provider::Package::Yum::RPMPackage.new("larger", larger, "x86_64")
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
        sm = Chef::Provider::Package::Yum::RPMPackage.new("smaller", smaller, "x86_64")
        lg = Chef::Provider::Package::Yum::RPMPackage.new("larger", larger, "x86_64")
        sm.should be == lg
      end
    end

  end
end
