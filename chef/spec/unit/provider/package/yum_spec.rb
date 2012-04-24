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

require 'spec_helper'

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
      :package_available? => true,
      :version_available? => true,
      :allow_multi_install => [ "kernel" ],
      :package_repository => "base" 
    )
    Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
    @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
    @stderr = StringIO.new
    @pid = mock("PID")
  end

  describe "#load_current_resource" do
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

    context "when arch in package_name" do
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
        @yum_cache.stub!(:package_available?).and_return(true)
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
          elsif package_name == "testing" || package_name == "testing.beta3"
            nil
          end
        end
        @yum_cache.stub!(:candidate_version) do |package_name, arch|
          # no candidate for package_name/new_package_name
          nil
        end
        @yum_cache.stub!(:package_available?).and_return(true)
        Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
        @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
        # annoying side effect of the fun stub'ing above
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
        @yum_cache.stub!(:package_available?).and_return(true)
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
        end.and_return("something")
        @yum_cache.stub!(:package_available?).and_return(true)
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

    it "should search provides if package name can't be found then set package_name to match" do
      @yum_cache = mock(
        'Chef::Provider::Yum::YumCache',
        :reload_installed => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.18.el5",
        :package_available? => false,
        :version_available? => true
      )
      Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
      pkg = Chef::Provider::Package::Yum::RPMPackage.new("test-package", "1.2.4-11.18.el5", "x86_64", [])
      @yum_cache.should_receive(:packages_from_require).and_return([pkg])
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      @provider.load_current_resource
      @new_resource.package_name.should == "test-package"
    end

    it "should search provides if package name can't be found, warn about multiple matches, but use the first one" do
      @yum_cache = mock(
        'Chef::Provider::Yum::YumCache',
        :reload_installed => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.18.el5",
        :package_available? => false,
        :version_available? => true
      )
      Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
      pkg_x = Chef::Provider::Package::Yum::RPMPackage.new("test-package-x", "1.2.4-11.18.el5", "x86_64", [])
      pkg_y = Chef::Provider::Package::Yum::RPMPackage.new("test-package-y", "1.2.6-11.3.el5", "i386", [])
      @yum_cache.should_receive(:packages_from_require).and_return([pkg_x, pkg_y])
      Chef::Log.should_receive(:warn).exactly(1).times.with(%r{matched multiple Provides})
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      @provider.load_current_resource
      @new_resource.package_name.should == "test-package-x"
    end

    it "should search provides if no package is available - if no match in installed provides then load the complete set" do
      @yum_cache = mock(
        'Chef::Provider::Yum::YumCache',
        :reload_installed => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.18.el5",
        :package_available? => false,
        :version_available? => true
      )
      Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
      @yum_cache.should_receive(:packages_from_require).twice.and_return([])
      @yum_cache.should_receive(:reload_provides)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      @provider.load_current_resource
    end

    it "should search provides if no package is available and not load the complete set if action is :remove or :purge" do
      @yum_cache = mock(
        'Chef::Provider::Yum::YumCache',
        :reload_installed => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.18.el5",
        :package_available? => false,
        :version_available? => true
      )
      Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      @yum_cache.should_receive(:packages_from_require).once.and_return([])
      @yum_cache.should_not_receive(:reload_provides)
      @new_resource.action(:remove)
      @provider.load_current_resource
      @yum_cache.should_receive(:packages_from_require).once.and_return([])
      @yum_cache.should_not_receive(:reload_provides)
      @new_resource.action(:purge)
      @provider.load_current_resource
    end

    it "should search provides if no package is available - if no match in provides leave the name intact" do
      @yum_cache = mock(
        'Chef::Provider::Yum::YumCache',
        :reload_provides => true,
        :reload_installed => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.18.el5",
        :package_available? => false,
        :version_available? => true
      )
      Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
      @yum_cache.should_receive(:packages_from_require).twice.and_return([])
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      @provider.load_current_resource
      @new_resource.package_name.should == "cups"
    end
  end

  describe "#install_package" do
    it "should run yum install with the package name and version" do
      @provider.load_current_resource
      Chef::Provider::Package::Yum::RPMUtils.stub!(:rpmvercmp).and_return(-1)
      @provider.should_receive(:yum_command).with(
        "yum -d0 -e0 -y install emacs-1.0"
      )
      @provider.install_package("emacs", "1.0")
    end

    it "should run yum localinstall if given a path to an rpm" do
      @new_resource.stub!(:source).and_return("/tmp/emacs-21.4-20.el5.i386.rpm")
      @provider.should_receive(:yum_command).with(
        "yum -d0 -e0 -y localinstall /tmp/emacs-21.4-20.el5.i386.rpm"
      )
      @provider.install_package("emacs", "21.4-20.el5")
    end

    it "should run yum localinstall if given a path to an rpm as the package" do
      @new_resource = Chef::Resource::Package.new("/tmp/emacs-21.4-20.el5.i386.rpm")
      ::File.stub!(:exists?).and_return(true)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      @new_resource.source.should == "/tmp/emacs-21.4-20.el5.i386.rpm"
      @provider.should_receive(:yum_command).with(
        "yum -d0 -e0 -y localinstall /tmp/emacs-21.4-20.el5.i386.rpm"
      )
      @provider.install_package("/tmp/emacs-21.4-20.el5.i386.rpm", "21.4-20.el5")
    end

    it "should run yum install with the package name, version and arch" do
      @provider.load_current_resource
      @new_resource.stub!(:arch).and_return("i386")
      Chef::Provider::Package::Yum::RPMUtils.stub!(:rpmvercmp).and_return(-1)
      @provider.should_receive(:yum_command).with(
        "yum -d0 -e0 -y install emacs-21.4-20.el5.i386"
      )
      @provider.install_package("emacs", "21.4-20.el5")
    end

    it "installs the package with the options given in the resource" do
      @provider.load_current_resource
      @provider.candidate_version = '11'
      @new_resource.stub!(:options).and_return("--disablerepo epmd")
      Chef::Provider::Package::Yum::RPMUtils.stub!(:rpmvercmp).and_return(-1)
      @provider.should_receive(:yum_command).with(
        "yum -d0 -e0 -y --disablerepo epmd install cups-11"
      )
      @provider.install_package(@new_resource.name, @provider.candidate_version)
    end

    it "should raise an exception if the package is not available" do
      @yum_cache = mock(
        'Chef::Provider::Yum::YumCache',
        :reload_from_cache => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.18.el5_2.3",
        :package_available? => true,
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
        :package_available? => true,
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
        :package_available? => true,
        :version_available? => true,
        :allow_multi_install => [ "cups" ],
        :package_repository => "base"
      )
      Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      @provider.load_current_resource
      @provider.should_receive(:yum_command).with(
        "yum -d0 -e0 -y install cups-1.2.4-11.15.el5"
      )
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
        :package_available? => true,
        :version_available? => true,
        :allow_multi_install => [],
        :package_repository => "base"
      )
      Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      @provider.load_current_resource
      @provider.should_receive(:yum_command).with(
        "yum -d0 -e0 -y downgrade cups-1.2.4-11.15.el5"
      )
      @provider.install_package("cups", "1.2.4-11.15.el5")
    end

    it "should run yum install then flush the cache if :after is true" do
      @new_resource.stub!(:flush_cache).and_return({:after => true, :before => false})
      @provider.load_current_resource
      Chef::Provider::Package::Yum::RPMUtils.stub!(:rpmvercmp).and_return(-1)
      @provider.should_receive(:yum_command).with(
        "yum -d0 -e0 -y install emacs-1.0"
      )
      @yum_cache.should_receive(:reload).once
      @provider.install_package("emacs", "1.0")
    end

    it "should run yum install then not flush the cache if :after is false" do
      @new_resource.stub!(:flush_cache).and_return({:after => false, :before => false})
      @provider.load_current_resource
      Chef::Provider::Package::Yum::RPMUtils.stub!(:rpmvercmp).and_return(-1)
      @provider.should_receive(:yum_command).with(
        "yum -d0 -e0 -y install emacs-1.0"
      )
      @yum_cache.should_not_receive(:reload)
      @provider.install_package("emacs", "1.0")
    end
  end

  describe "#upgrade_package" do
    it "should run yum install if the package is installed and a version is given" do
      @provider.load_current_resource
      @provider.candidate_version = '11'
      Chef::Provider::Package::Yum::RPMUtils.stub!(:rpmvercmp).and_return(-1)
      @provider.should_receive(:yum_command).with(
        "yum -d0 -e0 -y install cups-11"
      )
      @provider.upgrade_package(@new_resource.name, @provider.candidate_version)
    end

    it "should run yum install if the package is not installed" do
      @provider.load_current_resource
      @current_resource = Chef::Resource::Package.new('cups')
      @provider.candidate_version = '11'
      Chef::Provider::Package::Yum::RPMUtils.stub!(:rpmvercmp).and_return(-1)
      @provider.should_receive(:yum_command).with(
        "yum -d0 -e0 -y install cups-11"
      )
      @provider.upgrade_package(@new_resource.name, @provider.candidate_version)
    end

    it "should raise an exception if candidate version is older than the installed version" do
      @yum_cache = mock(
        'Chef::Provider::Yum::YumCache',
        :reload_installed => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.15.el5",
        :package_available? => true,
        :version_available? => true,
        :allow_multi_install => [ "kernel" ]
      )
      Chef::Provider::Package::Yum::YumCache.stub!(:instance).and_return(@yum_cache)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      @provider.load_current_resource
      lambda { @provider.upgrade_package("cups", "1.2.4-11.15.el5") }.should raise_error(Chef::Exceptions::Package, %r{is newer than candidate package})
    end
  end

  describe '#action_upgrade' do
    # Test our little workaround, some crossover into Chef::Provider::Package territory
    it "should call action_upgrade in the parent if the current resource version is nil" do
      @yum_cache.stub!(:installed_version).and_return(nil)
      @provider.load_current_resource
      @current_resource = Chef::Resource::Package.new('cups')
      @provider.candidate_version = '11'
      @provider.should_receive(:upgrade_package).with(
        "cups",
        "11"
      )
      @provider.action_upgrade
    end

    it "should call action_upgrade in the parent if the candidate version is nil" do
      @provider.load_current_resource
      @current_resource = Chef::Resource::Package.new('cups')
      @provider.candidate_version = nil
      @provider.should_not_receive(:upgrade_package)
      @provider.action_upgrade
    end

    it "should call action_upgrade in the parent if the candidate is newer" do
      @provider.load_current_resource
      @current_resource = Chef::Resource::Package.new('cups')
      @provider.candidate_version = '11'
      @provider.should_receive(:upgrade_package).with(
        "cups",
        "11"
      )
      @provider.action_upgrade
    end

    it "should not call action_upgrade in the parent if the candidate is older" do
      @yum_cache.stub!(:installed_version).and_return("12")
      @provider.load_current_resource
      @current_resource = Chef::Resource::Package.new('cups')
      @provider.candidate_version = '11'
      @provider.should_not_receive(:upgrade_package)
      @provider.action_upgrade
    end
  end

  describe "#remove_package" do
    it "should run yum remove with the package name" do
      @provider.should_receive(:yum_command).with(
        "yum -d0 -e0 -y remove emacs-1.0"
      )
      @provider.remove_package("emacs", "1.0")
    end

    it "should run yum remove with the package name and arch" do
      @new_resource.stub!(:arch).and_return("x86_64")
      @provider.should_receive(:yum_command).with(
        "yum -d0 -e0 -y remove emacs-1.0.x86_64"
      )
      @provider.remove_package("emacs", "1.0")
    end
  end

  describe "#purge_package" do
    it "should run yum remove with the package name" do
      @provider.should_receive(:yum_command).with(
        "yum -d0 -e0 -y remove emacs-1.0"
      )
      @provider.purge_package("emacs", "1.0")
    end
  end

  describe "#yum_command" do
    it "should run yum once if it exits with a return code of 0" do
      @status = mock("Status", :exitstatus => 0)
      @provider.stub!(:output_of_command).and_return([@status, "", ""])
      @provider.should_receive(:output_of_command).once.with(
        "yum -d0 -e0 -y install emacs-1.0",
        {}
      )
      @provider.yum_command("yum -d0 -e0 -y install emacs-1.0")
    end

    it "should run yum once if it exits with a return code > 0 and no scriptlet failures" do
      @status = mock("Status", :exitstatus => 2)
      @provider.stub!(:output_of_command).and_return([@status, "failure failure", "problem problem"])
      @provider.should_receive(:output_of_command).once.with(
        "yum -d0 -e0 -y install emacs-1.0",
        {}
      )
      lambda { @provider.yum_command("yum -d0 -e0 -y install emacs-1.0") }.should raise_error(Chef::Exceptions::Exec)
    end

    it "should run yum once if it exits with a return code of 1 and %pre scriptlet failures" do
      @status = mock("Status", :exitstatus => 1)
      @provider.stub!(:output_of_command).and_return([@status, "error: %pre(demo-1-1.el5.centos.x86_64) scriptlet failed, exit status 2", ""])
      @provider.should_receive(:output_of_command).once.with(
        "yum -d0 -e0 -y install emacs-1.0",
        {}
      )
      # will still raise an exception, can't stub out the subsequent call
      lambda { @provider.yum_command("yum -d0 -e0 -y install emacs-1.0") }.should raise_error(Chef::Exceptions::Exec)
    end

    it "should run yum twice if it exits with a return code of 1 and %post scriptlet failures" do
      @status = mock("Status", :exitstatus => 1)
      @provider.stub!(:output_of_command).and_return([@status, "error: %post(demo-1-1.el5.centos.x86_64) scriptlet failed, exit status 2", ""])
      @provider.should_receive(:output_of_command).twice.with(
        "yum -d0 -e0 -y install emacs-1.0",
        {}
      )
      # will still raise an exception, can't stub out the subsequent call
      lambda { @provider.yum_command("yum -d0 -e0 -y install emacs-1.0") }.should raise_error(Chef::Exceptions::Exec)
    end
  end
end
