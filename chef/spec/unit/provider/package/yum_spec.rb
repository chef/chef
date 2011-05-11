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
      :reload_installed => true,
      :reset => true,
      :installed_version => "1.2.4-11.18.el5",
      :candidate_version => "1.2.4-11.18.el5_2.3",
      :version_available? => true,
      :allow_multi_install => [ "kernel" ]
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

    it "should raise an error if a candidate version can't be found" do
      @yum_cache = mock(
        'Chef::Provider::Yum::YumCache',
        :reload_installed => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => nil,
        :version_available? => true
      )
      Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Package, %r{don't have a version of package})
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
        # annoying side effect of the fun stub'ing above
        lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Package, %r{don't have a version of package})
        @provider.new_resource.package_name.should == "testing.beta3"
        @provider.new_resource.arch.should == nil 
        @provider.arch.should == nil 

        @new_resource = Chef::Resource::YumPackage.new('testing.beta3.more')
        @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
        lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Package, %r{don't have a version of package})
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
        lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Package, %r{don't have a version of package})
        @provider.new_resource.package_name.should == "testing.beta3"
        @provider.new_resource.arch.should == nil 
        @provider.arch.should == nil 

        @new_resource = Chef::Resource::YumPackage.new('testing.beta3.more')
        @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
        lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Package, %r{don't have a version of package})
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
        end.and_return("something")
        Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
        @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
        @provider.load_current_resource
        @provider.new_resource.package_name.should == "testing.i386"
        @provider.new_resource.arch.should == "x86_64" 
      end
    end

    it "should flush the cache if :before is true" do
      @new_resource.stub!(:flush_cache).and_return({:after => false, :before => true}) 
      @yum_cache.should_receive(:reload).once
      @provider.load_current_resource
    end

    it "should flush the cache if :before is false" do
      @new_resource.stub!(:flush_cache).and_return({:after => false, :before => false}) 
      @yum_cache.should_not_receive(:reload)
      @provider.load_current_resource
    end
  end

  describe "when installing a package" do
    it "should run yum install with the package name and version" do
      @provider.load_current_resource
      Chef::Provider::Package::Yum::RPMUtils.stub!(:rpmvercmp).and_return(-1)
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
      @provider.load_current_resource
      @new_resource.stub!(:arch).and_return("i386")
      Chef::Provider::Package::Yum::RPMUtils.stub!(:rpmvercmp).and_return(-1)
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y install emacs-21.4-20.el5.i386"
      })
      @provider.install_package("emacs", "21.4-20.el5")
    end

    it "installs the package with the options given in the resource" do
      @provider.load_current_resource
      @provider.candidate_version = '11'
      @new_resource.stub!(:options).and_return("--disablerepo epmd")
      Chef::Provider::Package::Yum::RPMUtils.stub!(:rpmvercmp).and_return(-1)
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y --disablerepo epmd install cups-11"
      })
      @provider.install_package(@new_resource.name, @provider.candidate_version)
    end

    it "should raise an exception if the package is not available" do
      @yum_cache = mock(
        'Chef::Provider::Yum::YumCache',
        :reload_from_cache => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.18.el5_2.3",
        :version_available? => nil
      )
      Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      lambda { @provider.install_package("lolcats", "0.99") }.should raise_error(Chef::Exceptions::Package, %r{Version .* not found})
    end

    it "should raise an exception if candidate version is older than the installed version and allow_downgrade is false" do
      @new_resource.stub!(:allow_downgrade).and_return(false)
      @yum_cache = mock(
        'Chef::Provider::Yum::YumCache',
        :reload_installed => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.15.el5",
        :version_available? => true,
        :allow_multi_install => [ "kernel" ]
      )
      Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      @provider.load_current_resource
      lambda { @provider.install_package("cups", "1.2.4-11.15.el5") }.should raise_error(Chef::Exceptions::Package, %r{is newer than candidate package})
    end

    it "should not raise an exception if candidate version is older than the installed version and the package is list in yum's installonlypkg option" do
      @yum_cache = mock(
        'Chef::Provider::Yum::YumCache',
        :reload_installed => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.15.el5",
        :version_available? => true,
        :allow_multi_install => [ "cups" ]
      )
      Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      @provider.load_current_resource
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y install cups-1.2.4-11.15.el5"
      })
      @provider.install_package("cups", "1.2.4-11.15.el5")
    end

    it "should run yum downgrade if candidate version is older than the installed version and allow_downgrade is true" do
      @new_resource.stub!(:allow_downgrade).and_return(true)
      @yum_cache = mock(
        'Chef::Provider::Yum::YumCache',
        :reload_installed => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.15.el5",
        :version_available? => true,
        :allow_multi_install => []
      )
      Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      @provider.load_current_resource
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y downgrade cups-1.2.4-11.15.el5"
      })
      @provider.install_package("cups", "1.2.4-11.15.el5")
    end

    it "should run yum install then flush the cache if :after is true" do
      @new_resource.stub!(:flush_cache).and_return({:after => true, :before => false})
      @provider.load_current_resource
      Chef::Provider::Package::Yum::RPMUtils.stub!(:rpmvercmp).and_return(-1)
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y install emacs-1.0"
      })
      @yum_cache.should_receive(:reload).once
      @provider.install_package("emacs", "1.0")
    end

    it "should run yum install then not flush the cache if :after is false" do
      @new_resource.stub!(:flush_cache).and_return({:after => false, :before => false})
      @provider.load_current_resource
      Chef::Provider::Package::Yum::RPMUtils.stub!(:rpmvercmp).and_return(-1)
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y install emacs-1.0"
      })
      @yum_cache.should_not_receive(:reload)
      @provider.install_package("emacs", "1.0")
    end
  end

  describe "when upgrading a package" do
    it "should run yum install if the package is installed and a version is given" do
      @provider.load_current_resource
      @provider.candidate_version = '11'
      Chef::Provider::Package::Yum::RPMUtils.stub!(:rpmvercmp).and_return(-1)
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y install cups-11"
      })
      @provider.upgrade_package(@new_resource.name, @provider.candidate_version)
    end

    it "should run yum install if the package is not installed" do
      @provider.load_current_resource
      @current_resource = Chef::Resource::Package.new('cups')
      @provider.candidate_version = '11'
      Chef::Provider::Package::Yum::RPMUtils.stub!(:rpmvercmp).and_return(-1)
      @provider.should_receive(:run_command_with_systems_locale).with({
        :command => "yum -d0 -e0 -y install cups-11"
      })
      @provider.upgrade_package(@new_resource.name, @provider.candidate_version)
    end

    it "should raise an exception if candidate version is older than the installed version" do
      @yum_cache = mock(
        'Chef::Provider::Yum::YumCache',
        :reload_installed => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.15.el5",
        :version_available? => true,
        :allow_multi_install => [ "kernel" ]
      )
      Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      @provider.load_current_resource
      lambda { @provider.upgrade_package("cups", "1.2.4-11.15.el5") }.should raise_error(Chef::Exceptions::Package, %r{is newer than candidate package})
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

describe Chef::Provider::Package::Yum::RPMDbPackage do
  before(:each) do
    # name, version, arch, installed, available
    @rpm_x = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-b", "0:1.6.5-9.36.el5", "noarch", false, true)
    @rpm_y = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-b", "0:1.6.5-9.36.el5", "noarch", true, true)
    @rpm_z = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-b", "0:1.6.5-9.36.el5", "noarch", true, false)
  end

  describe "initialize" do
    it "should return a Chef::Provider::Package::Yum::RPMDbPackage object" do
      @rpm_x.should be_kind_of(Chef::Provider::Package::Yum::RPMDbPackage)
    end
  end

  describe "available" do
    it "should return true" do
      @rpm_x.available.should be == true
      @rpm_y.available.should be == true
      @rpm_z.available.should be == false 
    end
  end
 
  describe "installed" do
    it "should return true" do
      @rpm_x.installed.should be == false 
      @rpm_y.installed.should be == true
      @rpm_z.installed.should be == true 
    end
  end

end

# thanks resource_collection_spec.rb!
describe Chef::Provider::Package::Yum::RPMDb do
  before(:each) do
    @rpmdb = Chef::Provider::Package::Yum::RPMDb.new
    # name, version, arch, installed, available
    @rpm_v = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-a", "0:1.6.5-9.36.el5", "i386", true, false)
    @rpm_w = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-b", "0:1.6.5-9.36.el5", "i386", true, true)
    @rpm_x = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-b", "0:1.6.5-9.36.el5", "x86_64", false, true)
    @rpm_y = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-b", "1:1.6.5-9.36.el5", "x86_64", true, true)
    @rpm_z = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-c", "0:1.6.5-9.36.el5", "noarch", true, true)
    @rpm_z_mirror = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-c", "0:1.6.5-9.36.el5", "noarch", true, true)
  end

  describe "initialize" do
    it "should return a Chef::Provider::Package::Yum::RPMDb object" do
      @rpmdb.should be_kind_of(Chef::Provider::Package::Yum::RPMDb)
    end
  end

  describe "push" do
    it "should accept an RPMDbPackage object through pushing" do
      lambda { @rpmdb.push(@rpm_w) }.should_not raise_error
    end

    it "should accept multiple RPMDbPackage object through pushing" do
      lambda { @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z) }.should_not raise_error
    end

    it "should only accept an RPMDbPackage object" do
      lambda { @rpmdb.push("string") }.should raise_error
    end
    
    it "should add the package to the package db" do
      @rpmdb.push(@rpm_w)
      @rpmdb["test-package-b"].should_not be == nil
    end

    it "should add conditionally add the package to the available list" do
      @rpmdb.available_size.should be == 0 
      @rpmdb.push(@rpm_v, @rpm_w)
      @rpmdb.available_size.should be == 1
    end

    it "should add conditionally add the package to the installed list" do
      @rpmdb.installed_size.should be == 0 
      @rpmdb.push(@rpm_w, @rpm_x)
      @rpmdb.installed_size.should be == 1
    end

    it "should have a total of 2 packages in the RPMDb" do
      @rpmdb.size.should be == 0
      @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
      @rpmdb.size.should be == 2
    end

    it "should keep the Array unique when a duplicate is pushed" do
      @rpmdb.push(@rpm_z, @rpm_z_mirror)
      @rpmdb["test-package-c"].size.should be == 1
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
      @rpmdb.lookup("test-package-b").should be_kind_of(Array)
    end
  end

  describe "[]" do
    it "should return an Array of RPMPackage objects though the [index] operator" do
      @rpmdb << @rpm_w 
      @rpmdb["test-package-b"].should be_kind_of(Array)
    end

    it "should return an Array of 3 RPMPackage objects" do
      @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
      @rpmdb["test-package-b"].size.should be == 3
    end

    it "should return an Array of RPMPackage objects sorted from newest to oldest" do
      @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
      @rpmdb["test-package-b"][0].should be == @rpm_y
      @rpmdb["test-package-b"][1].should be == @rpm_x
      @rpmdb["test-package-b"][2].should be == @rpm_w
    end
  end

  describe "clear" do
    it "should clear the RPMDb" do
      @rpmdb.should_receive(:clear_available).once
      @rpmdb.should_receive(:clear_installed).once
      @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
      @rpmdb.size.should_not be == 0
      @rpmdb.clear
      @rpmdb.size.should be == 0
    end
  end

  describe "clear_available" do
    it "should clear the available list" do
      @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
      @rpmdb.available_size.should_not be == 0
      @rpmdb.clear_available
      @rpmdb.available_size.should be == 0
    end
  end

  describe "available?" do
    it "should return true if a package is available" do
      @rpmdb.available?(@rpm_w).should be == false 
      @rpmdb.push(@rpm_v, @rpm_w)
      @rpmdb.available?(@rpm_v).should be == false
      @rpmdb.available?(@rpm_w).should be == true
    end
  end

  describe "clear_installed" do
    it "should clear the installed list" do
      @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
      @rpmdb.installed_size.should_not be == 0
      @rpmdb.clear_installed
      @rpmdb.installed_size.should be == 0
    end
  end

  describe "installed?" do
    it "should return true if a package is installed" do
      @rpmdb.installed?(@rpm_w).should be == false 
      @rpmdb.push(@rpm_w, @rpm_x)
      @rpmdb.installed?(@rpm_w).should be == true
      @rpmdb.installed?(@rpm_x).should be == false
    end
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
[option installonlypkgs] kernel kernel-bigmem kernel-enterprise
erlang-mochiweb 0 1.4.1 1.el5 x86_64 i
zip 0 2.31 2.el5 x86_64 r
zisofs-tools 0 1.0.6 3.2.2 x86_64 a
zlib 0 1.2.3 3 x86_64 r
zlib 0 1.2.3 3 i386 r
zlib-devel 0 1.2.3 3 i386 a
zlib-devel 0 1.2.3 3 x86_64 r
znc 0 0.098 1.el5 x86_64 a
znc-devel 0 0.098 1.el5 i386 a
znc-devel 0 0.098 1.el5 x86_64 a
znc-extra 0 0.098 1.el5 x86_64 a
znc-modtcl 0 0.098 1.el5 x86_64 a
EOF

    yum_dump_bad_output_separators = <<EOF
zip 0 2.31 2.el5 x86_64 r
zlib 0 1.2.3 3 x86_64 i bad
zlib-devel 0 1.2.3 3 i386 a
bad zlib-devel 0 1.2.3 3 x86_64 i
znc-modtcl 0 0.098 1.el5 x86_64 a bad
EOF

    yum_dump_bad_output_type = <<EOF
zip 0 2.31 2.el5 x86_64 r
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

    it "should register reload for start of Chef::Client runs" do
      Chef::Provider::Package::Yum::YumCache.reset_instance
      Chef::Client.should_receive(:when_run_starts) do |&b|
        b.should_not be_nil
      end
      @yc = Chef::Provider::Package::Yum::YumCache.instance
    end
  end

  describe "refresh" do
    it "should implicitly call yum-dump.py only once by default after being instantiated" do
      @yc.should_receive(:popen4).once
      @yc.installed_version("zlib")
      @yc.reset
      @yc.installed_version("zlib")
    end

    it "should run yum-dump.py using the system python when next_refresh is for :all" do
      @yc.reload
      @yc.should_receive(:popen4).with(%r{^/usr/bin/python .*/yum-dump.py --options$}, :waitlast=>true)
      @yc.refresh
    end

    it "should run yum-dump.py with the installed flag when next_refresh is for :installed" do
      @yc.reload_installed
      @yc.should_receive(:popen4).with(%r{^/usr/bin/python .*/yum-dump.py --installed$}, :waitlast=>true)
      @yc.refresh
    end

    it "should warn about invalid data with too many separators" do
      @yc.stub!(:popen4).and_yield(@pid, @stdin, @stdout_bad_separators, @stderr).and_return(@status)
      Chef::Log.should_receive(:warn).exactly(3).times.with(%r{Problem parsing})
      @yc.refresh
    end

    it "should warn about invalid data with an incorrect type" do
      @yc.stub!(:popen4).and_yield(@pid, @stdin, @stdout_bad_type, @stderr).and_return(@status)
      Chef::Log.should_receive(:warn).exactly(2).times.with(%r{Skipping line})
      @yc.refresh
    end

    it "should warn about no output from yum-dump.py" do
      @yc.stub!(:popen4).and_yield(@pid, @stdin, [], @stderr).and_return(@status)
      Chef::Log.should_receive(:warn).exactly(1).times.with(%r{no output from yum-dump.py})
      @yc.refresh
    end

    it "should raise exception yum-dump.py exits with a non zero status" do
      @yc.stub!(:popen4).and_yield(@pid, @stdin, [], @stderr).and_return(@status_bad)
      lambda { @yc.refresh}.should raise_error(Chef::Exceptions::Package, %r{CentOS-Base.repo, line: 12})
    end

    it "should parse type 'i' into an installed state for a package" do
      @yc.available_version("erlang-mochiweb").should be == nil
      @yc.installed_version("erlang-mochiweb").should_not be == nil
    end

    it "should parse type 'a' into an available state for a package" do
      @yc.available_version("znc").should_not be == nil
      @yc.installed_version("znc").should be == nil
    end

    it "should parse type 'r' into an installed and available states for a package" do
      @yc.available_version("zip").should_not be == nil
      @yc.installed_version("zip").should_not be == nil
    end

    it "should parse installonlypkgs from yum-dump.py options output" do
      @yc.allow_multi_install.should be == %w{kernel kernel-bigmem kernel-enterprise}
    end
  end

  describe "installed_version" do
    it "should take one or two arguments" do
      lambda { @yc.installed_version("zip") }.should_not raise_error(ArgumentError)
      lambda { @yc.installed_version("zip", "i386") }.should_not raise_error(ArgumentError)
      lambda { @yc.installed_version("zip", "i386", "extra") }.should raise_error(ArgumentError)
    end

    it "should return version-release for matching package regardless of arch" do
      @yc.installed_version("zip", "x86_64").should be == "2.31-2.el5"
      @yc.installed_version("zip", nil).should be == "2.31-2.el5"
    end

    it "should return version-release for matching package and arch" do
      @yc.installed_version("zip", "x86_64").should be == "2.31-2.el5"
      @yc.installed_version("zisofs-tools", "i386").should be == nil
    end

    it "should return nil for an unmatched package" do
      @yc.installed_version(nil, nil).should be == nil 
      @yc.installed_version("test1", nil).should be == nil 
      @yc.installed_version("test2", "x86_64").should be == nil 
    end
  end

  describe "available_version" do
    it "should take one or two arguments" do
      lambda { @yc.available_version("zisofs-tools") }.should_not raise_error(ArgumentError)
      lambda { @yc.available_version("zisofs-tools", "i386") }.should_not raise_error(ArgumentError)
      lambda { @yc.available_version("zisofs-tools", "i386", "extra") }.should raise_error(ArgumentError)
    end

    it "should return version-release for matching package regardless of arch" do
      @yc.available_version("zip", "x86_64").should be == "2.31-2.el5"
      @yc.available_version("zip", nil).should be == "2.31-2.el5"
    end

    it "should return version-release for matching package and arch" do
      @yc.available_version("zip", "x86_64").should be == "2.31-2.el5"
      @yc.available_version("zisofs-tools", "i386").should be == nil
    end

    it "should return nil for an unmatched package" do
      @yc.available_version(nil, nil).should be == nil 
      @yc.available_version("test1", nil).should be == nil 
      @yc.available_version("test2", "x86_64").should be == nil 
    end
  end

  describe "version_available" do
    it "should take two or three arguments" do
      lambda { @yc.version_available?("zisofs-tools") }.should raise_error(ArgumentError)
      lambda { @yc.version_available?("zisofs-tools", "1.0.6-3.2.2") }.should_not raise_error(ArgumentError)
      lambda { @yc.version_available?("zisofs-tools", "1.0.6-3.2.2", "x86_64") }.should_not raise_error(ArgumentError)
    end

    it "should return true if our package-version-arch is available" do
      @yc.version_available?("zisofs-tools", "1.0.6-3.2.2", "x86_64").should be == true 
    end

    it "should return true if our package-version, no arch, is available" do
      @yc.version_available?("zisofs-tools", "1.0.6-3.2.2", nil).should be == true 
      @yc.version_available?("zisofs-tools", "1.0.6-3.2.2").should be == true 
    end

    it "should return false if our package-version-arch isn't available" do
      @yc.version_available?("zisofs-tools", "1.0.6-3.2.2", "pretend").should be == false 
      @yc.version_available?("zisofs-tools", "pretend", "x86_64").should be == false 
      @yc.version_available?("pretend", "1.0.6-3.2.2", "x86_64").should be == false 
    end

    it "should return false if our package-version, no arch, isn't available" do
      @yc.version_available?("zisofs-tools", "pretend", nil).should be == false 
      @yc.version_available?("zisofs-tools", "pretend").should be == false 
      @yc.version_available?("pretend", "1.0.6-3.2.2").should be == false 
    end
  end

  describe "reset" do
    it "should empty the installed and available packages RPMDb" do
      @yc.available_version("zip", "x86_64").should be == "2.31-2.el5"
      @yc.installed_version("zip", "x86_64").should be == "2.31-2.el5"
      @yc.reset
      @yc.available_version("zip", "x86_64").should be == nil
      @yc.installed_version("zip", "x86_64").should be == nil
    end
  end

end
