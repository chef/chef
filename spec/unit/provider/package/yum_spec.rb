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
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Package.new('cups')
    @status = double("Status", :exitstatus => 0)
    @yum_cache = double(
      'Chef::Provider::Yum::YumCache',
      :reload_installed => true,
      :reset => true,
      :installed_version => "1.2.4-11.18.el5",
      :candidate_version => "1.2.4-11.18.el5_2.3",
      :package_available? => true,
      :version_available? => true,
      :allow_multi_install => [ "kernel" ],
      :package_repository => "base",
      :disable_extra_repo_control => true
    )
    allow(Chef::Provider::Package::Yum::YumCache).to receive(:instance).and_return(@yum_cache)
    @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
    @pid = double("PID")
  end

  describe "when loading the current system state" do
    it "should create a current resource with the name of the new_resource" do
      @provider.load_current_resource
      expect(@provider.current_resource.name).to eq("cups")
    end

    it "should set the current resources package name to the new resources package name" do
      @provider.load_current_resource
      expect(@provider.current_resource.package_name).to eq(["cups"])
    end

    it "should set the installed version to nil on the current resource if no installed package" do
      allow(@yum_cache).to receive(:installed_version).and_return([nil])
      @provider.load_current_resource
      expect(@provider.current_resource.version).to eq([nil])
    end

    it "should set the installed version if yum has one" do
      @provider.load_current_resource
      expect(@provider.current_resource.version).to eq(["1.2.4-11.18.el5"])
    end

    it "should set the candidate version if yum info has one" do
      @provider.load_current_resource
      expect(@provider.candidate_version).to eql(["1.2.4-11.18.el5_2.3"])
    end

    it "should return the current resouce" do
      expect(@provider.load_current_resource).to eql(@provider.current_resource)
    end

    describe "when arch in package_name" do
      it "should set the arch if no existing package_name is found and new_package_name+new_arch is available" do
        @new_resource = Chef::Resource::YumPackage.new('testing.noarch')
        @yum_cache = double(
          'Chef::Provider::Yum::YumCache'
        )
        allow(@yum_cache).to receive(:installed_version) do |package_name, arch|
          # nothing installed for package_name/new_package_name
          nil
        end
        allow(@yum_cache).to receive(:candidate_version) do |package_name, arch|
          if package_name == "testing.noarch" || package_name == "testing.more.noarch"
            nil
          # candidate for new_package_name
          elsif package_name == "testing" || package_name == "testing.more"
            "1.1"
          end
        end
        allow(@yum_cache).to receive(:package_available?).and_return(true)
        allow(@yum_cache).to receive(:disable_extra_repo_control).and_return(true)
        allow(Chef::Provider::Package::Yum::YumCache).to receive(:instance).and_return(@yum_cache)
        @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
        @provider.load_current_resource
        expect(@provider.new_resource.package_name).to eq(["testing"])
        expect(@provider.new_resource.arch).to eq("noarch")
        expect(@provider.arch).to eq("noarch")

        @new_resource = Chef::Resource::YumPackage.new('testing.more.noarch')
        @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
        @provider.load_current_resource
        expect(@provider.new_resource.package_name).to eq(["testing.more"])
        expect(@provider.new_resource.arch).to eq("noarch")
        expect(@provider.arch).to eq("noarch")
      end

      it "should not set the arch when an existing package_name is found" do
        @new_resource = Chef::Resource::YumPackage.new('testing.beta3')
        @yum_cache = double(
          'Chef::Provider::Yum::YumCache'
        )
        allow(@yum_cache).to receive(:installed_version) do |package_name, arch|
          # installed for package_name
          if package_name == "testing.beta3" || package_name == "testing.beta3.more"
            "1.1"
          elsif package_name == "testing" || package_name == "testing.beta3"
            nil
          end
        end
        allow(@yum_cache).to receive(:candidate_version) do |package_name, arch|
          # no candidate for package_name/new_package_name
          nil
        end
        allow(@yum_cache).to receive(:package_available?).and_return(true)
        allow(@yum_cache).to receive(:disable_extra_repo_control).and_return(true)
        allow(Chef::Provider::Package::Yum::YumCache).to receive(:instance).and_return(@yum_cache)
        @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
        # annoying side effect of the fun stub'ing above
        @provider.load_current_resource
        expect(@provider.new_resource.package_name).to eq(["testing.beta3"])
        expect(@provider.new_resource.arch).to eq(nil)
        expect(@provider.arch).to eq(nil)

        @new_resource = Chef::Resource::YumPackage.new('testing.beta3.more')
        @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
        @provider.load_current_resource
        expect(@provider.new_resource.package_name).to eq(["testing.beta3.more"])
        expect(@provider.new_resource.arch).to eq(nil)
        expect(@provider.arch).to eq(nil)
      end

      it "should not set the arch when no existing package_name or new_package_name+new_arch is found" do
        @new_resource = Chef::Resource::YumPackage.new('testing.beta3')
        @yum_cache = double(
          'Chef::Provider::Yum::YumCache'
        )
        allow(@yum_cache).to receive(:installed_version) do |package_name, arch|
          # nothing installed for package_name/new_package_name
          nil
        end
        allow(@yum_cache).to receive(:candidate_version) do |package_name, arch|
          # no candidate for package_name/new_package_name
          nil
        end
        allow(@yum_cache).to receive(:package_available?).and_return(true)
        allow(@yum_cache).to receive(:disable_extra_repo_control).and_return(true)
        allow(Chef::Provider::Package::Yum::YumCache).to receive(:instance).and_return(@yum_cache)
        @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
        @provider.load_current_resource
        expect(@provider.new_resource.package_name).to eq(["testing.beta3"])
        expect(@provider.new_resource.arch).to eq(nil)
        expect(@provider.arch).to eq(nil)

        @new_resource = Chef::Resource::YumPackage.new('testing.beta3.more')
        @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
        @provider.load_current_resource
        expect(@provider.new_resource.package_name).to eq(["testing.beta3.more"])
        expect(@provider.new_resource.arch).to eq(nil)
        expect(@provider.arch).to eq(nil)
      end

      it "should ensure it doesn't clobber an existing arch if passed" do
        @new_resource = Chef::Resource::YumPackage.new('testing.i386')
        @new_resource.arch("x86_64")
        @yum_cache = double(
          'Chef::Provider::Yum::YumCache'
        )
         allow(@yum_cache).to receive(:installed_version) do |package_name, arch|
           # nothing installed for package_name/new_package_name
         nil
        end
        allow(@yum_cache).to receive(:candidate_version) do |package_name, arch|
          if package_name == "testing.noarch"
            nil
          # candidate for new_package_name
          elsif package_name == "testing"
            "1.1"
          end
        end.and_return("something")
        allow(@yum_cache).to receive(:package_available?).and_return(true)
        allow(@yum_cache).to receive(:disable_extra_repo_control).and_return(true)
        allow(Chef::Provider::Package::Yum::YumCache).to receive(:instance).and_return(@yum_cache)
        @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
        @provider.load_current_resource
        expect(@provider.new_resource.package_name).to eq(["testing.i386"])
        expect(@provider.new_resource.arch).to eq("x86_64")
      end
    end

    it "should flush the cache if :before is true" do
      allow(@new_resource).to receive(:flush_cache).and_return({:after => false, :before => true})
      expect(@yum_cache).to receive(:reload).once
      @provider.load_current_resource
    end

    it "should flush the cache if :before is false" do
      allow(@new_resource).to receive(:flush_cache).and_return({:after => false, :before => false})
      expect(@yum_cache).not_to receive(:reload)
      @provider.load_current_resource
    end

    it "should detect --enablerepo or --disablerepo when passed among options, collect them preserving order and notify the yum cache" do
      allow(@new_resource).to receive(:options).and_return("--stuff --enablerepo=foo --otherthings --disablerepo=a,b,c  --enablerepo=bar")
      expect(@yum_cache).to receive(:enable_extra_repo_control).with("--enablerepo=foo --disablerepo=a,b,c --enablerepo=bar")
      @provider.load_current_resource
    end

    it "should let the yum cache know extra repos are disabled if --enablerepo or --disablerepo aren't among options" do
      allow(@new_resource).to receive(:options).and_return("--stuff --otherthings")
      expect(@yum_cache).to receive(:disable_extra_repo_control)
      @provider.load_current_resource
    end

    it "should let the yum cache know extra repos are disabled if options aren't set" do
      allow(@new_resource).to receive(:options).and_return(nil)
      expect(@yum_cache).to receive(:disable_extra_repo_control)
      @provider.load_current_resource
    end

    it "should search provides if package name can't be found then set package_name to match" do
      @yum_cache = double(
        'Chef::Provider::Yum::YumCache',
        :reload_installed => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.18.el5",
        :package_available? => false,
        :version_available? => true,
        :disable_extra_repo_control => true
      )
      allow(Chef::Provider::Package::Yum::YumCache).to receive(:instance).and_return(@yum_cache)
      pkg = Chef::Provider::Package::Yum::RPMPackage.new("test-package", "1.2.4-11.18.el5", "x86_64", [])
      expect(@yum_cache).to receive(:packages_from_require).and_return([pkg])
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      @provider.load_current_resource
      expect(@new_resource.package_name).to eq(["test-package"])
    end

    it "should search provides if package name can't be found, warn about multiple matches, but use the first one" do
      @yum_cache = double(
        'Chef::Provider::Yum::YumCache',
        :reload_installed => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.18.el5",
        :package_available? => false,
        :version_available? => true,
        :disable_extra_repo_control => true
      )
      allow(Chef::Provider::Package::Yum::YumCache).to receive(:instance).and_return(@yum_cache)
      pkg_x = Chef::Provider::Package::Yum::RPMPackage.new("test-package-x", "1.2.4-11.18.el5", "x86_64", [])
      pkg_y = Chef::Provider::Package::Yum::RPMPackage.new("test-package-y", "1.2.6-11.3.el5", "i386", [])
      expect(@yum_cache).to receive(:packages_from_require).and_return([pkg_x, pkg_y])
      expect(Chef::Log).to receive(:warn).exactly(1).times.with(%r{matched multiple Provides})
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      @provider.load_current_resource
      expect(@new_resource.package_name).to eq(["test-package-x"])
    end

    it "should search provides if no package is available - if no match in installed provides then load the complete set" do
      @yum_cache = double(
        'Chef::Provider::Yum::YumCache',
        :reload_installed => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.18.el5",
        :package_available? => false,
        :version_available? => true,
        :disable_extra_repo_control => true
      )
      allow(Chef::Provider::Package::Yum::YumCache).to receive(:instance).and_return(@yum_cache)
      expect(@yum_cache).to receive(:packages_from_require).twice.and_return([])
      expect(@yum_cache).to receive(:reload_provides)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      @provider.load_current_resource
    end

    it "should search provides if no package is available and not load the complete set if action is :remove or :purge" do
      @yum_cache = double(
        'Chef::Provider::Yum::YumCache',
        :reload_installed => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.18.el5",
        :package_available? => false,
        :version_available? => true,
        :disable_extra_repo_control => true
      )
      allow(Chef::Provider::Package::Yum::YumCache).to receive(:instance).and_return(@yum_cache)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      expect(@yum_cache).to receive(:packages_from_require).once.and_return([])
      expect(@yum_cache).not_to receive(:reload_provides)
      @new_resource.action(:remove)
      @provider.load_current_resource
      expect(@yum_cache).to receive(:packages_from_require).once.and_return([])
      expect(@yum_cache).not_to receive(:reload_provides)
      @new_resource.action(:purge)
      @provider.load_current_resource
    end

    it "should search provides if no package is available - if no match in provides leave the name intact" do
      @yum_cache = double(
        'Chef::Provider::Yum::YumCache',
        :reload_provides => true,
        :reload_installed => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.18.el5",
        :package_available? => false,
        :version_available? => true,
        :disable_extra_repo_control => true
      )
      allow(Chef::Provider::Package::Yum::YumCache).to receive(:instance).and_return(@yum_cache)
      expect(@yum_cache).to receive(:packages_from_require).twice.and_return([])
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      @provider.load_current_resource
      expect(@new_resource.package_name).to eq(["cups"])
    end
  end

  describe "when installing a package" do
    it "should run yum install with the package name and version" do
      @provider.load_current_resource
      allow(Chef::Provider::Package::Yum::RPMUtils).to receive(:rpmvercmp).and_return(-1)
      expect(@provider).to receive(:yum_command).with(
        "yum -d0 -e0 -y install cups-1.2.4-11.19.el5"
      )
      @provider.install_package(["cups"], ["1.2.4-11.19.el5"])
    end

    it "should run yum localinstall if given a path to an rpm" do
      allow(@new_resource).to receive(:source).and_return("/tmp/emacs-21.4-20.el5.i386.rpm")
      expect(@provider).to receive(:yum_command).with(
        "yum -d0 -e0 -y localinstall /tmp/emacs-21.4-20.el5.i386.rpm"
      )
      @provider.install_package(["emacs"], ["21.4-20.el5"])
    end

    it "should run yum localinstall if given a path to an rpm as the package" do
      @new_resource = Chef::Resource::Package.new("/tmp/emacs-21.4-20.el5.i386.rpm")
      allow(::File).to receive(:exists?).and_return(true)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      expect(@new_resource.source).to eq("/tmp/emacs-21.4-20.el5.i386.rpm")
      expect(@provider).to receive(:yum_command).with(
        "yum -d0 -e0 -y localinstall /tmp/emacs-21.4-20.el5.i386.rpm"
      )
      @provider.install_package(["/tmp/emacs-21.4-20.el5.i386.rpm"], ["21.4-20.el5"])
    end

    it "should run yum install with the package name, version and arch" do
      @provider.load_current_resource
      allow(@new_resource).to receive(:arch).and_return("i386")
      allow(Chef::Provider::Package::Yum::RPMUtils).to receive(:rpmvercmp).and_return(-1)
      expect(@provider).to receive(:yum_command).with(
        "yum -d0 -e0 -y install cups-1.2.4-11.19.el5.i386"
      )
      @provider.install_package(["cups"], ["1.2.4-11.19.el5"])
    end

    it "installs the package with the options given in the resource" do
      @provider.load_current_resource
      @provider.candidate_version = ['11']
      allow(@new_resource).to receive(:options).and_return("--disablerepo epmd")
      allow(Chef::Provider::Package::Yum::RPMUtils).to receive(:rpmvercmp).and_return(-1)
      expect(@provider).to receive(:yum_command).with(
        "yum -d0 -e0 -y --disablerepo epmd install cups-11"
      )
      @provider.install_package(@new_resource.name, @provider.candidate_version)
    end

    it "should raise an exception if the package is not available" do
      @yum_cache = double(
        'Chef::Provider::Yum::YumCache',
        :reload_from_cache => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.18.el5_2.3",
        :package_available? => true,
        :version_available? => nil,
        :disable_extra_repo_control => true
      )
      allow(Chef::Provider::Package::Yum::YumCache).to receive(:instance).and_return(@yum_cache)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      expect { @provider.install_package("lolcats", "0.99") }.to raise_error(Chef::Exceptions::Package, %r{Version .* not found})
    end

    it "should raise an exception if candidate version is older than the installed version and allow_downgrade is false" do
      allow(@new_resource).to receive(:allow_downgrade).and_return(false)
      @yum_cache = double(
        'Chef::Provider::Yum::YumCache',
        :reload_installed => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.15.el5",
        :package_available? => true,
        :version_available? => true,
        :allow_multi_install => [ "kernel" ],
        :disable_extra_repo_control => true
      )
      allow(Chef::Provider::Package::Yum::YumCache).to receive(:instance).and_return(@yum_cache)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      @provider.load_current_resource
      expect { @provider.install_package("cups", "1.2.4-11.15.el5") }.to raise_error(Chef::Exceptions::Package, %r{is newer than candidate package})
    end

    it "should not raise an exception if candidate version is older than the installed version and the package is list in yum's installonlypkg option" do
      @yum_cache = double(
        'Chef::Provider::Yum::YumCache',
        :reload_installed => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.15.el5",
        :package_available? => true,
        :version_available? => true,
        :allow_multi_install => [ "cups" ],
        :package_repository => "base",
        :disable_extra_repo_control => true
      )
      allow(Chef::Provider::Package::Yum::YumCache).to receive(:instance).and_return(@yum_cache)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      @provider.load_current_resource
      expect(@provider).to receive(:yum_command).with(
        "yum -d0 -e0 -y install cups-1.2.4-11.15.el5"
      )
      @provider.install_package("cups", "1.2.4-11.15.el5")
    end

    it "should run yum downgrade if candidate version is older than the installed version and allow_downgrade is true" do
      allow(@new_resource).to receive(:allow_downgrade).and_return(true)
      @yum_cache = double(
        'Chef::Provider::Yum::YumCache',
        :reload_installed => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.15.el5",
        :package_available? => true,
        :version_available? => true,
        :allow_multi_install => [],
        :package_repository => "base",
        :disable_extra_repo_control => true
      )
      allow(Chef::Provider::Package::Yum::YumCache).to receive(:instance).and_return(@yum_cache)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      @provider.load_current_resource
      expect(@provider).to receive(:yum_command).with(
        "yum -d0 -e0 -y downgrade cups-1.2.4-11.15.el5"
      )
      @provider.install_package("cups", "1.2.4-11.15.el5")
    end

    it "should run yum install then flush the cache if :after is true" do
      allow(@new_resource).to receive(:flush_cache).and_return({:after => true, :before => false})
      @provider.load_current_resource
      allow(Chef::Provider::Package::Yum::RPMUtils).to receive(:rpmvercmp).and_return(-1)
      expect(@provider).to receive(:yum_command).with(
        "yum -d0 -e0 -y install cups-1.2.4-11.15.el5"
      )
      expect(@yum_cache).to receive(:reload).once
      @provider.install_package("cups", "1.2.4-11.15.el5")
    end

    it "should run yum install then not flush the cache if :after is false" do
      allow(@new_resource).to receive(:flush_cache).and_return({:after => false, :before => false})
      @provider.load_current_resource
      allow(Chef::Provider::Package::Yum::RPMUtils).to receive(:rpmvercmp).and_return(-1)
      expect(@provider).to receive(:yum_command).with(
        "yum -d0 -e0 -y install cups-1.2.4-11.15.el5"
      )
      expect(@yum_cache).not_to receive(:reload)
      @provider.install_package("cups", "1.2.4-11.15.el5")
    end
  end

  describe "when upgrading a package" do
    it "should run yum install if the package is installed and a version is given" do
      @provider.load_current_resource
      @provider.candidate_version = '11'
      allow(Chef::Provider::Package::Yum::RPMUtils).to receive(:rpmvercmp).and_return(-1)
      expect(@provider).to receive(:yum_command).with(
        "yum -d0 -e0 -y install cups-11"
      )
      @provider.upgrade_package(@new_resource.name, @provider.candidate_version)
    end

    it "should run yum install if the package is not installed" do
      @provider.load_current_resource
      @current_resource = Chef::Resource::Package.new('cups')
      @provider.candidate_version = '11'
      allow(Chef::Provider::Package::Yum::RPMUtils).to receive(:rpmvercmp).and_return(-1)
      expect(@provider).to receive(:yum_command).with(
        "yum -d0 -e0 -y install cups-11"
      )
      @provider.upgrade_package(@new_resource.name, @provider.candidate_version)
    end

    it "should raise an exception if candidate version is older than the installed version" do
      @yum_cache = double(
        'Chef::Provider::Yum::YumCache',
        :reload_installed => true,
        :reset => true,
        :installed_version => "1.2.4-11.18.el5",
        :candidate_version => "1.2.4-11.15.el5",
        :package_available? => true,
        :version_available? => true,
        :allow_multi_install => [ "kernel" ],
        :disable_extra_repo_control => true
      )
      allow(Chef::Provider::Package::Yum::YumCache).to receive(:instance).and_return(@yum_cache)
      @provider = Chef::Provider::Package::Yum.new(@new_resource, @run_context)
      @provider.load_current_resource
      expect { @provider.upgrade_package("cups", "1.2.4-11.15.el5") }.to raise_error(Chef::Exceptions::Package, %r{is newer than candidate package})
    end

    # Test our little workaround, some crossover into Chef::Provider::Package territory
    it "should call action_upgrade in the parent if the current resource version is nil" do
      allow(@yum_cache).to receive(:installed_version).and_return(nil)
      @provider.load_current_resource
      @current_resource = Chef::Resource::Package.new('cups')
      @provider.candidate_version = ['11']
      expect(@provider).to receive(:upgrade_package).with(
        ["cups"],
        ["11"]
      )
      @provider.action_upgrade
    end

    it "should call action_upgrade in the parent if the candidate version is nil" do
      @provider.load_current_resource
      @current_resource = Chef::Resource::Package.new('cups')
      @provider.candidate_version = [nil]
      expect(@provider).not_to receive(:upgrade_package)
      @provider.action_upgrade
    end

    it "should call action_upgrade in the parent if the candidate is newer" do
      @provider.load_current_resource
      @current_resource = Chef::Resource::Package.new('cups')
      @provider.candidate_version = ['11']
      expect(@provider).to receive(:upgrade_package).with(
        ["cups"],
        ["11"]
      )
      @provider.action_upgrade
    end

    it "should not call action_upgrade in the parent if the candidate is older" do
      allow(@yum_cache).to receive(:installed_version).and_return("12")
      @provider.load_current_resource
      @current_resource = Chef::Resource::Package.new('cups')
      @provider.candidate_version = ['11']
      expect(@provider).not_to receive(:upgrade_package)
      @provider.action_upgrade
    end
  end

  describe "when removing a package" do
    it "should run yum remove with the package name" do
      expect(@provider).to receive(:yum_command).with(
        "yum -d0 -e0 -y remove emacs-1.0"
      )
      @provider.remove_package("emacs", "1.0")
    end

    it "should run yum remove with the package name and arch" do
      allow(@new_resource).to receive(:arch).and_return("x86_64")
      expect(@provider).to receive(:yum_command).with(
        "yum -d0 -e0 -y remove emacs-1.0.x86_64"
      )
      @provider.remove_package("emacs", "1.0")
    end
  end

  describe "when purging a package" do
    it "should run yum remove with the package name" do
      expect(@provider).to receive(:yum_command).with(
        "yum -d0 -e0 -y remove emacs-1.0"
      )
      @provider.purge_package("emacs", "1.0")
    end
  end

  describe "when running yum" do
    it "should run yum once if it exits with a return code of 0" do
      @status = double("Status", :exitstatus => 0)
      allow(@provider).to receive(:output_of_command).and_return([@status, "", ""])
      expect(@provider).to receive(:output_of_command).once.with(
        "yum -d0 -e0 -y install emacs-1.0",
        {:timeout => Chef::Config[:yum_timeout]}
      )
      @provider.yum_command("yum -d0 -e0 -y install emacs-1.0")
    end

    it "should run yum once if it exits with a return code > 0 and no scriptlet failures" do
      @status = double("Status", :exitstatus => 2)
      allow(@provider).to receive(:output_of_command).and_return([@status, "failure failure", "problem problem"])
      expect(@provider).to receive(:output_of_command).once.with(
        "yum -d0 -e0 -y install emacs-1.0",
        {:timeout => Chef::Config[:yum_timeout]}
      )
      expect { @provider.yum_command("yum -d0 -e0 -y install emacs-1.0") }.to raise_error(Chef::Exceptions::Exec)
    end

    it "should run yum once if it exits with a return code of 1 and %pre scriptlet failures" do
      @status = double("Status", :exitstatus => 1)
      allow(@provider).to receive(:output_of_command).and_return([@status, "error: %pre(demo-1-1.el5.centos.x86_64) scriptlet failed, exit status 2", ""])
      expect(@provider).to receive(:output_of_command).once.with(
        "yum -d0 -e0 -y install emacs-1.0",
        {:timeout => Chef::Config[:yum_timeout]}
      )
      # will still raise an exception, can't stub out the subsequent call
      expect { @provider.yum_command("yum -d0 -e0 -y install emacs-1.0") }.to raise_error(Chef::Exceptions::Exec)
    end

    it "should run yum twice if it exits with a return code of 1 and %post scriptlet failures" do
      @status = double("Status", :exitstatus => 1)
      allow(@provider).to receive(:output_of_command).and_return([@status, "error: %post(demo-1-1.el5.centos.x86_64) scriptlet failed, exit status 2", ""])
      expect(@provider).to receive(:output_of_command).twice.with(
        "yum -d0 -e0 -y install emacs-1.0",
        {:timeout => Chef::Config[:yum_timeout]}
      )
      # will still raise an exception, can't stub out the subsequent call
      expect { @provider.yum_command("yum -d0 -e0 -y install emacs-1.0") }.to raise_error(Chef::Exceptions::Exec)
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
        expect(@rpmutils.version_parse(x)).to eq(y)
      end
    end

    it "parses strange epoch strings" do
      [
        [ ":3.3", [ 0, "3.3", nil ] ],
        [ "-1:1.7.3", [ nil, nil, "1:1.7.3" ] ],
        [ "-:20020927", [ nil, nil, ":20020927" ] ]
      ].each do |x, y|
        expect(@rpmutils.version_parse(x)).to eq(y)
      end
    end

    it "parses known good version strings" do
      [
        [ "3.3", [ nil, "3.3", nil ] ],
        [ "1.7.3", [ nil, "1.7.3", nil ] ],
        [ "20020927", [ nil, "20020927", nil ] ]
      ].each do |x, y|
        expect(@rpmutils.version_parse(x)).to eq(y)
      end
    end

    it "parses strange version strings" do
      [
        [ "3..3", [ nil, "3..3", nil ] ],
        [ "0001.7.3", [ nil, "0001.7.3", nil ] ],
        [ "20020927,3", [ nil, "20020927,3", nil ] ]
      ].each do |x, y|
        expect(@rpmutils.version_parse(x)).to eq(y)
      end
    end

    it "parses known good version release strings" do
      [
        [ "3.3-0.pre3.1.60.el5_5.1", [ nil, "3.3", "0.pre3.1.60.el5_5.1" ] ],
        [ "1.7.3-1jpp.2.el5", [ nil, "1.7.3", "1jpp.2.el5" ] ],
        [ "20020927-46.el5", [ nil, "20020927", "46.el5" ] ]
      ].each do |x, y|
        expect(@rpmutils.version_parse(x)).to eq(y)
      end
    end

    it "parses strange version release strings" do
      [
        [ "3.3-", [ nil, "3.3", nil ] ],
        [ "-1jpp.2.el5", [ nil, nil, "1jpp.2.el5" ] ],
        [ "-0020020927-46.el5", [ nil, "-0020020927", "46.el5" ] ]
      ].each do |x, y|
        expect(@rpmutils.version_parse(x)).to eq(y)
      end
    end
  end

  describe "rpmvercmp" do
    before do
      @rpmutils = Chef::Provider::Package::Yum::RPMUtils
    end

    it "should validate version compare logic for standard examples" do
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
        expect(@rpmutils.rpmvercmp(x,y)).to eq(result)
      end
    end

    it "should validate version compare logic for strange examples" do
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
        expect(@rpmutils.rpmvercmp(x,y)).to eq(result)
      end
    end

    it "tests isalnum good input" do
      [ 'a', 'z', 'A', 'Z', '0', '9' ].each do |t|
        expect(@rpmutils.isalnum(t)).to eq(true)
      end
    end

    it "tests isalnum bad input" do
      [ '-', '.', '!', '^', ':', '_' ].each do |t|
        expect(@rpmutils.isalnum(t)).to eq(false)
      end
    end

    it "tests isalpha good input" do
      [ 'a', 'z', 'A', 'Z', ].each do |t|
        expect(@rpmutils.isalpha(t)).to eq(true)
      end
    end

    it "tests isalpha bad input" do
      [ '0', '9', '-', '.', '!', '^', ':', '_' ].each do |t|
        expect(@rpmutils.isalpha(t)).to eq(false)
      end
    end

    it "tests isdigit good input" do
      [ '0', '9', ].each do |t|
        expect(@rpmutils.isdigit(t)).to eq(true)
      end
    end

    it "tests isdigit bad input" do
      [ 'A', 'z', '-', '.', '!', '^', ':', '_' ].each do |t|
        expect(@rpmutils.isdigit(t)).to eq(false)
      end
    end
  end

end

describe Chef::Provider::Package::Yum::RPMVersion do
  describe "new - with parsing" do
    before do
      @rpmv = Chef::Provider::Package::Yum::RPMVersion.new("1:1.6.5-9.36.el5")
    end

    it "should expose evr (name-version-release) available" do
      expect(@rpmv.e).to eq(1)
      expect(@rpmv.v).to eq("1.6.5")
      expect(@rpmv.r).to eq("9.36.el5")

      expect(@rpmv.evr).to eq("1:1.6.5-9.36.el5")
    end

    it "should output a version-release string" do
      expect(@rpmv.to_s).to eq("1.6.5-9.36.el5")
    end
  end

  describe "new - no parsing" do
    before do
      @rpmv = Chef::Provider::Package::Yum::RPMVersion.new("1", "1.6.5", "9.36.el5")
    end

    it "should expose evr (name-version-release) available" do
      expect(@rpmv.e).to eq(1)
      expect(@rpmv.v).to eq("1.6.5")
      expect(@rpmv.r).to eq("9.36.el5")

      expect(@rpmv.evr).to eq("1:1.6.5-9.36.el5")
    end

    it "should output a version-release string" do
      expect(@rpmv.to_s).to eq("1.6.5-9.36.el5")
    end
  end

  it "should raise an error unless passed 1 or 3 args" do
    expect {
      Chef::Provider::Package::Yum::RPMVersion.new()
    }.to raise_error(ArgumentError)
    expect {
      Chef::Provider::Package::Yum::RPMVersion.new("1:1.6.5-9.36.el5")
    }.not_to raise_error
    expect {
      Chef::Provider::Package::Yum::RPMVersion.new("1:1.6.5-9.36.el5", "extra")
    }.to raise_error(ArgumentError)
    expect {
      Chef::Provider::Package::Yum::RPMVersion.new("1", "1.6.5", "9.36.el5")
    }.not_to raise_error
    expect {
      Chef::Provider::Package::Yum::RPMVersion.new("1", "1.6.5", "9.36.el5", "extra")
    }.to raise_error(ArgumentError)
  end

  # thanks version_class_spec.rb!
  describe "compare" do
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
        sm = Chef::Provider::Package::Yum::RPMVersion.new(smaller)
        lg = Chef::Provider::Package::Yum::RPMVersion.new(larger)
        expect(sm).to be < lg
        expect(lg).to be > sm
        expect(sm).not_to eq(lg)
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
        sm = Chef::Provider::Package::Yum::RPMVersion.new(smaller)
        lg = Chef::Provider::Package::Yum::RPMVersion.new(larger)
        expect(sm).to be < lg
        expect(lg).to be > sm
        expect(sm).not_to eq(lg)
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
        sm = Chef::Provider::Package::Yum::RPMVersion.new(smaller)
        lg = Chef::Provider::Package::Yum::RPMVersion.new(larger)
        expect(sm).to eq(lg)
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
        sm = Chef::Provider::Package::Yum::RPMVersion.new(smaller)
        lg = Chef::Provider::Package::Yum::RPMVersion.new(larger)
        expect(sm).to eq(lg)
      end
    end
  end

  describe "partial compare" do
    it "should compare based on partial epoch-version-release data" do
      [
        # smaller, larger
        [ "0:1.1.1-1",
          "1:" ],
        [ "0:1.1.1-1",
          "0:1.1.2" ],
        [ "0:1.1.1-1",
          "0:1.1.2-1" ],
        [ "0:",
          "1:1.1.1-1" ],
        [ "0:1.1.1",
          "0:1.1.2-1" ],
        [ "0:1.1.1-1",
          "0:1.1.2-1" ],
      ].each do |smaller, larger|
        sm = Chef::Provider::Package::Yum::RPMVersion.new(smaller)
        lg = Chef::Provider::Package::Yum::RPMVersion.new(larger)
        expect(sm.partial_compare(lg)).to eq(-1)
        expect(lg.partial_compare(sm)).to eq(1)
        expect(sm.partial_compare(lg)).not_to eq(0)
      end
    end

    it "should verify equality based on partial epoch-version-release data" do
      [
        [ "0:",
          "0:1.1.1-1" ],
        [ "0:1.1.1",
          "0:1.1.1-1" ],
        [ "0:1.1.1-1",
          "0:1.1.1-1" ],
      ].each do |smaller, larger|
        sm = Chef::Provider::Package::Yum::RPMVersion.new(smaller)
        lg = Chef::Provider::Package::Yum::RPMVersion.new(larger)
        expect(sm.partial_compare(lg)).to eq(0)
      end
    end
  end

end

describe Chef::Provider::Package::Yum::RPMPackage do
  describe "new - with parsing" do
    before do
      @rpm = Chef::Provider::Package::Yum::RPMPackage.new("testing", "1:1.6.5-9.36.el5", "x86_64", [])
    end

    it "should expose nevra (name-epoch-version-release-arch) available" do
      expect(@rpm.name).to eq("testing")
      expect(@rpm.version.e).to eq(1)
      expect(@rpm.version.v).to eq("1.6.5")
      expect(@rpm.version.r).to eq("9.36.el5")
      expect(@rpm.arch).to eq("x86_64")

      expect(@rpm.nevra).to eq("testing-1:1.6.5-9.36.el5.x86_64")
      expect(@rpm.to_s).to eq(@rpm.nevra)
    end

    it "should always have at least one provide, itself" do
      expect(@rpm.provides.size).to eq(1)
      @rpm.provides[0].name == "testing"
      @rpm.provides[0].version.evr == "1:1.6.5-9.36.el5"
      @rpm.provides[0].flag == :==
    end
  end

  describe "new - no parsing" do
    before do
      @rpm = Chef::Provider::Package::Yum::RPMPackage.new("testing", "1", "1.6.5", "9.36.el5", "x86_64", [])
    end

    it "should expose nevra (name-epoch-version-release-arch) available" do
      expect(@rpm.name).to eq("testing")
      expect(@rpm.version.e).to eq(1)
      expect(@rpm.version.v).to eq("1.6.5")
      expect(@rpm.version.r).to eq("9.36.el5")
      expect(@rpm.arch).to eq("x86_64")

      expect(@rpm.nevra).to eq("testing-1:1.6.5-9.36.el5.x86_64")
      expect(@rpm.to_s).to eq(@rpm.nevra)
    end

    it "should always have at least one provide, itself" do
      expect(@rpm.provides.size).to eq(1)
      @rpm.provides[0].name == "testing"
      @rpm.provides[0].version.evr == "1:1.6.5-9.36.el5"
      @rpm.provides[0].flag == :==
    end
  end

  it "should raise an error unless passed 4 or 6 args" do
    expect {
      Chef::Provider::Package::Yum::RPMPackage.new()
    }.to raise_error(ArgumentError)
    expect {
      Chef::Provider::Package::Yum::RPMPackage.new("testing")
    }.to raise_error(ArgumentError)
    expect {
      Chef::Provider::Package::Yum::RPMPackage.new("testing", "1:1.6.5-9.36.el5")
    }.to raise_error(ArgumentError)
    expect {
      Chef::Provider::Package::Yum::RPMPackage.new("testing", "1:1.6.5-9.36.el5", "x86_64")
    }.to raise_error(ArgumentError)
    expect {
      Chef::Provider::Package::Yum::RPMPackage.new("testing", "1:1.6.5-9.36.el5", "x86_64", [])
    }.not_to raise_error
    expect {
      Chef::Provider::Package::Yum::RPMPackage.new("testing", "1", "1.6.5", "9.36.el5", "x86_64")
    }.to raise_error(ArgumentError)
    expect {
      Chef::Provider::Package::Yum::RPMPackage.new("testing", "1", "1.6.5", "9.36.el5", "x86_64", [])
    }.not_to raise_error
    expect {
      Chef::Provider::Package::Yum::RPMPackage.new("testing", "1", "1.6.5", "9.36.el5", "x86_64", [], "extra")
    }.to raise_error(ArgumentError)
  end

  describe "<=>" do
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
        sm = Chef::Provider::Package::Yum::RPMPackage.new(smaller, "0:0.0.1-1", "x86_64", [])
        lg = Chef::Provider::Package::Yum::RPMPackage.new(larger, "0:0.0.1-1", "x86_64", [])
        expect(sm).to be < lg
        expect(lg).to be > sm
        expect(sm).not_to eq(lg)
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
        sm = Chef::Provider::Package::Yum::RPMPackage.new("test-package", "0:0.0.1-1", smaller, [])
        lg = Chef::Provider::Package::Yum::RPMPackage.new("test-package", "0:0.0.1-1", larger, [])
        expect(sm).to be < lg
        expect(lg).to be > sm
        expect(sm).not_to eq(lg)
      end
    end
  end

end

describe Chef::Provider::Package::Yum::RPMDbPackage do
  before(:each) do
    # name, version, arch, installed, available, repoid
    @rpm_x = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-b", "0:1.6.5-9.36.el5", "noarch", [], false, true, "base")
    @rpm_y = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-b", "0:1.6.5-9.36.el5", "noarch", [], true, true, "extras")
    @rpm_z = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-b", "0:1.6.5-9.36.el5", "noarch", [], true, false, "other")
  end

  describe "initialize" do
    it "should return a Chef::Provider::Package::Yum::RPMDbPackage object" do
      expect(@rpm_x).to be_kind_of(Chef::Provider::Package::Yum::RPMDbPackage)
    end
  end

  describe "available" do
    it "should return true" do
      expect(@rpm_x.available).to eq(true)
      expect(@rpm_y.available).to eq(true)
      expect(@rpm_z.available).to eq(false)
    end
  end

  describe "installed" do
    it "should return true" do
      expect(@rpm_x.installed).to eq(false)
      expect(@rpm_y.installed).to eq(true)
      expect(@rpm_z.installed).to eq(true)
    end
  end

  describe "repoid" do
    it "should return the source repository repoid" do
      expect(@rpm_x.repoid).to eq("base")
      expect(@rpm_y.repoid).to eq("extras")
      expect(@rpm_z.repoid).to eq("other")
    end
  end
end

describe Chef::Provider::Package::Yum::RPMDependency do
  describe "new - with parsing" do
    before do
      @rpmdep = Chef::Provider::Package::Yum::RPMDependency.new("testing", "1:1.6.5-9.36.el5", :==)
    end

    it "should expose name, version, flag available" do
      expect(@rpmdep.name).to eq("testing")
      expect(@rpmdep.version.e).to eq(1)
      expect(@rpmdep.version.v).to eq("1.6.5")
      expect(@rpmdep.version.r).to eq("9.36.el5")
      expect(@rpmdep.flag).to eq(:==)
    end
  end

  describe "new - no parsing" do
    before do
      @rpmdep = Chef::Provider::Package::Yum::RPMDependency.new("testing", "1", "1.6.5", "9.36.el5", :==)
    end

    it "should expose name, version, flag available" do
      expect(@rpmdep.name).to eq("testing")
      expect(@rpmdep.version.e).to eq(1)
      expect(@rpmdep.version.v).to eq("1.6.5")
      expect(@rpmdep.version.r).to eq("9.36.el5")
      expect(@rpmdep.flag).to eq(:==)
    end
  end

  it "should raise an error unless passed 3 or 5 args" do
    expect {
      Chef::Provider::Package::Yum::RPMDependency.new()
    }.to raise_error(ArgumentError)
    expect {
      Chef::Provider::Package::Yum::RPMDependency.new("testing")
    }.to raise_error(ArgumentError)
    expect {
      Chef::Provider::Package::Yum::RPMDependency.new("testing", "1:1.6.5-9.36.el5")
    }.to raise_error(ArgumentError)
    expect {
      Chef::Provider::Package::Yum::RPMDependency.new("testing", "1:1.6.5-9.36.el5", :==)
    }.not_to raise_error
    expect {
      Chef::Provider::Package::Yum::RPMDependency.new("testing", "1:1.6.5-9.36.el5", :==, "extra")
    }.to raise_error(ArgumentError)
    expect {
      Chef::Provider::Package::Yum::RPMDependency.new("testing", "1", "1.6.5", "9.36.el5", :==)
    }.not_to raise_error
    expect {
      Chef::Provider::Package::Yum::RPMDependency.new("testing", "1", "1.6.5", "9.36.el5", :==, "extra")
    }.to raise_error(ArgumentError)
  end

  describe "parse" do
    it "should parse a name, flag, version string into a valid RPMDependency object" do
      @rpmdep = Chef::Provider::Package::Yum::RPMDependency.parse("testing >= 1:1.6.5-9.36.el5")

      expect(@rpmdep.name).to eq("testing")
      expect(@rpmdep.version.e).to eq(1)
      expect(@rpmdep.version.v).to eq("1.6.5")
      expect(@rpmdep.version.r).to eq("9.36.el5")
      expect(@rpmdep.flag).to eq(:>=)
    end

    it "should parse a name into a valid RPMDependency object" do
      @rpmdep = Chef::Provider::Package::Yum::RPMDependency.parse("testing")

      expect(@rpmdep.name).to eq("testing")
      expect(@rpmdep.version.e).to eq(nil)
      expect(@rpmdep.version.v).to eq(nil)
      expect(@rpmdep.version.r).to eq(nil)
      expect(@rpmdep.flag).to eq(:==)
    end

    it "should parse an invalid string into the name of a RPMDependency object" do
      @rpmdep = Chef::Provider::Package::Yum::RPMDependency.parse("testing blah >")

      expect(@rpmdep.name).to eq("testing blah >")
      expect(@rpmdep.version.e).to eq(nil)
      expect(@rpmdep.version.v).to eq(nil)
      expect(@rpmdep.version.r).to eq(nil)
      expect(@rpmdep.flag).to eq(:==)
    end

    it "should parse various valid flags" do
      [
        [ ">", :> ],
        [ ">=", :>= ],
        [ "=", :== ],
        [ "==", :== ],
        [ "<=", :<= ],
        [ "<", :< ]
      ].each do |before, after|
        @rpmdep = Chef::Provider::Package::Yum::RPMDependency.parse("testing #{before} 1:1.1-1")
        expect(@rpmdep.flag).to eq(after)
      end
    end

    it "should parse various invalid flags and treat them as names" do
      [
        [ "<>", :== ],
        [ "!=", :== ],
        [ ">>", :== ],
        [ "<<", :== ],
        [ "!", :== ],
        [ "~", :== ]
      ].each do |before, after|
        @rpmdep = Chef::Provider::Package::Yum::RPMDependency.parse("testing #{before} 1:1.1-1")
        expect(@rpmdep.name).to eq("testing #{before} 1:1.1-1")
        expect(@rpmdep.flag).to eq(after)
      end
    end
  end

  describe "satisfy?" do
    it "should raise an error unless a RPMDependency is passed" do
      @rpmprovide = Chef::Provider::Package::Yum::RPMDependency.new("testing", "1:1.6.5-9.36.el5", :==)
      @rpmrequire = Chef::Provider::Package::Yum::RPMDependency.new("testing", "1:1.6.5-9.36.el5", :>=)
      expect {
        @rpmprovide.satisfy?("hi")
      }.to raise_error(ArgumentError)
      expect {
        @rpmprovide.satisfy?(@rpmrequire)
      }.not_to raise_error
    end

    it "should validate dependency satisfaction logic for standard examples" do
      [
        # names
        [ "test", "test", true ],
        [ "test", "foo", false ],
        # full: epoch:version-relese
        [ "testing = 1:1.1-1", "testing > 1:1.1-0", true ],
        [ "testing = 1:1.1-1", "testing >= 1:1.1-0", true ],
        [ "testing = 1:1.1-1", "testing >= 1:1.1-1", true ],
        [ "testing = 1:1.1-1", "testing = 1:1.1-1", true ],
        [ "testing = 1:1.1-1", "testing == 1:1.1-1", true ],
        [ "testing = 1:1.1-1", "testing <= 1:1.1-1", true ],
        [ "testing = 1:1.1-1", "testing <= 1:1.1-0", false ],
        [ "testing = 1:1.1-1", "testing < 1:1.1-0", false ],
        # partial: epoch:version
        [ "testing = 1:1.1", "testing > 1:1.0", true ],
        [ "testing = 1:1.1", "testing >= 1:1.0", true ],
        [ "testing = 1:1.1", "testing >= 1:1.1", true ],
        [ "testing = 1:1.1", "testing = 1:1.1", true ],
        [ "testing = 1:1.1", "testing == 1:1.1", true ],
        [ "testing = 1:1.1", "testing <= 1:1.1", true ],
        [ "testing = 1:1.1", "testing <= 1:1.0", false ],
        [ "testing = 1:1.1", "testing < 1:1.0", false ],
        # partial: epoch
        [ "testing = 1:", "testing > 0:", true ],
        [ "testing = 1:", "testing >= 0:", true ],
        [ "testing = 1:", "testing >= 1:", true ],
        [ "testing = 1:", "testing = 1:", true ],
        [ "testing = 1:", "testing == 1:", true ],
        [ "testing = 1:", "testing <= 1:", true ],
        [ "testing = 1:", "testing <= 0:", false ],
        [ "testing = 1:", "testing < 0:", false ],
        # mix and match!
        [ "testing = 1:1.1-1", "testing == 1:1.1", true ],
        [ "testing = 1:1.1-1", "testing == 1:", true ],
     ].each do |prov, req, result|
        @rpmprovide = Chef::Provider::Package::Yum::RPMDependency.parse(prov)
        @rpmrequire = Chef::Provider::Package::Yum::RPMDependency.parse(req)

        expect(@rpmprovide.satisfy?(@rpmrequire)).to eq(result)
        expect(@rpmrequire.satisfy?(@rpmprovide)).to eq(result)
      end
    end
  end

end

# thanks resource_collection_spec.rb!
describe Chef::Provider::Package::Yum::RPMDb do
  before(:each) do
    @rpmdb = Chef::Provider::Package::Yum::RPMDb.new
    # name, version, arch, installed, available
    deps_v = [
      Chef::Provider::Package::Yum::RPMDependency.parse("libz.so.1()(64bit)"),
      Chef::Provider::Package::Yum::RPMDependency.parse("test-package-a = 0:1.6.5-9.36.el5")
    ]
    deps_z = [
      Chef::Provider::Package::Yum::RPMDependency.parse("libz.so.1()(64bit)"),
      Chef::Provider::Package::Yum::RPMDependency.parse("config(test) = 0:1.6.5-9.36.el5"),
      Chef::Provider::Package::Yum::RPMDependency.parse("test-package-c = 0:1.6.5-9.36.el5")
    ]
    @rpm_v = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-a", "0:1.6.5-9.36.el5", "i386", deps_v, true, false, "base")
    @rpm_w = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-b", "0:1.6.5-9.36.el5", "i386", [], true, true, "extras")
    @rpm_x = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-b", "0:1.6.5-9.36.el5", "x86_64", [], false, true, "extras")
    @rpm_y = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-b", "1:1.6.5-9.36.el5", "x86_64", [], true, true, "extras")
    @rpm_z = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-c", "0:1.6.5-9.36.el5", "noarch", deps_z, true, true, "base")
    @rpm_z_mirror = Chef::Provider::Package::Yum::RPMDbPackage.new("test-package-c", "0:1.6.5-9.36.el5", "noarch", deps_z, true, true, "base")
  end

  describe "initialize" do
    it "should return a Chef::Provider::Package::Yum::RPMDb object" do
      expect(@rpmdb).to be_kind_of(Chef::Provider::Package::Yum::RPMDb)
    end
  end

  describe "push" do
    it "should accept an RPMDbPackage object through pushing" do
      expect { @rpmdb.push(@rpm_w) }.not_to raise_error
    end

    it "should accept multiple RPMDbPackage object through pushing" do
      expect { @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z) }.not_to raise_error
    end

    it "should only accept an RPMDbPackage object" do
      expect { @rpmdb.push("string") }.to raise_error
    end

    it "should add the package to the package db" do
      @rpmdb.push(@rpm_w)
      expect(@rpmdb["test-package-b"]).not_to eq(nil)
    end

    it "should add conditionally add the package to the available list" do
      expect(@rpmdb.available_size).to eq(0)
      @rpmdb.push(@rpm_v, @rpm_w)
      expect(@rpmdb.available_size).to eq(1)
    end

    it "should add conditionally add the package to the installed list" do
      expect(@rpmdb.installed_size).to eq(0)
      @rpmdb.push(@rpm_w, @rpm_x)
      expect(@rpmdb.installed_size).to eq(1)
    end

    it "should have a total of 2 packages in the RPMDb" do
      expect(@rpmdb.size).to eq(0)
      @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
      expect(@rpmdb.size).to eq(2)
    end

    it "should keep the Array unique when a duplicate is pushed" do
      @rpmdb.push(@rpm_z, @rpm_z_mirror)
      expect(@rpmdb["test-package-c"].size).to eq(1)
    end

    it "should register the package provides in the provides index" do
      @rpmdb.push(@rpm_v, @rpm_w, @rpm_z)
      expect(@rpmdb.lookup_provides("test-package-a")[0]).to eq(@rpm_v)
      expect(@rpmdb.lookup_provides("config(test)")[0]).to eq(@rpm_z)
      expect(@rpmdb.lookup_provides("libz.so.1()(64bit)")[0]).to eq(@rpm_v)
      expect(@rpmdb.lookup_provides("libz.so.1()(64bit)")[1]).to eq(@rpm_z)
    end
  end

  describe "<<" do
    it "should accept an RPMPackage object through the << operator" do
      expect { @rpmdb << @rpm_w }.not_to raise_error
    end
  end

  describe "lookup" do
    it "should return an Array of RPMPackage objects by index" do
      @rpmdb << @rpm_w
      expect(@rpmdb.lookup("test-package-b")).to be_kind_of(Array)
    end
  end

  describe "[]" do
    it "should return an Array of RPMPackage objects though the [index] operator" do
      @rpmdb << @rpm_w
      expect(@rpmdb["test-package-b"]).to be_kind_of(Array)
    end

    it "should return an Array of 3 RPMPackage objects" do
      @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
      expect(@rpmdb["test-package-b"].size).to eq(3)
    end

    it "should return an Array of RPMPackage objects sorted from newest to oldest" do
      @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
      expect(@rpmdb["test-package-b"][0]).to eq(@rpm_y)
      expect(@rpmdb["test-package-b"][1]).to eq(@rpm_x)
      expect(@rpmdb["test-package-b"][2]).to eq(@rpm_w)
    end
  end

  describe "lookup_provides" do
    it "should return an Array of RPMPackage objects by index" do
      @rpmdb << @rpm_z
      x = @rpmdb.lookup_provides("config(test)")
      expect(x).to be_kind_of(Array)
      expect(x[0]).to eq(@rpm_z)
    end
  end

  describe "clear" do
    it "should clear the RPMDb" do
      expect(@rpmdb).to receive(:clear_available).once
      expect(@rpmdb).to receive(:clear_installed).once
      @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
      expect(@rpmdb.size).not_to eq(0)
      expect(@rpmdb.lookup_provides("config(test)")).to be_kind_of(Array)
      @rpmdb.clear
      expect(@rpmdb.lookup_provides("config(test)")).to eq(nil)
      expect(@rpmdb.size).to eq(0)
    end
  end

  describe "clear_available" do
    it "should clear the available list" do
      @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
      expect(@rpmdb.available_size).not_to eq(0)
      @rpmdb.clear_available
      expect(@rpmdb.available_size).to eq(0)
    end
  end

  describe "available?" do
    it "should return true if a package is available" do
      expect(@rpmdb.available?(@rpm_w)).to eq(false)
      @rpmdb.push(@rpm_v, @rpm_w)
      expect(@rpmdb.available?(@rpm_v)).to eq(false)
      expect(@rpmdb.available?(@rpm_w)).to eq(true)
    end
  end

  describe "clear_installed" do
    it "should clear the installed list" do
      @rpmdb.push(@rpm_w, @rpm_x, @rpm_y, @rpm_z)
      expect(@rpmdb.installed_size).not_to eq(0)
      @rpmdb.clear_installed
      expect(@rpmdb.installed_size).to eq(0)
    end
  end

  describe "installed?" do
    it "should return true if a package is installed" do
      expect(@rpmdb.installed?(@rpm_w)).to eq(false)
      @rpmdb.push(@rpm_w, @rpm_x)
      expect(@rpmdb.installed?(@rpm_w)).to eq(true)
      expect(@rpmdb.installed?(@rpm_x)).to eq(false)
    end
  end

  describe "whatprovides" do
    it "should raise an error unless a RPMDependency is passed" do
      @rpmprovide = Chef::Provider::Package::Yum::RPMDependency.new("testing", "1:1.6.5-9.36.el5", :==)
      @rpmrequire = Chef::Provider::Package::Yum::RPMDependency.new("testing", "1:1.6.5-9.36.el5", :>=)
      expect {
        @rpmdb.whatprovides("hi")
      }.to raise_error(ArgumentError)
      expect {
        @rpmdb.whatprovides(@rpmrequire)
      }.not_to raise_error
    end

    it "should return an Array of packages statisfying a RPMDependency" do
      @rpmdb.push(@rpm_v, @rpm_w, @rpm_z)

      @rpmrequire = Chef::Provider::Package::Yum::RPMDependency.parse("test-package-a >= 1.6.5")
      x = @rpmdb.whatprovides(@rpmrequire)
      expect(x).to be_kind_of(Array)
      expect(x[0]).to eq(@rpm_v)

      @rpmrequire = Chef::Provider::Package::Yum::RPMDependency.parse("libz.so.1()(64bit)")
      x = @rpmdb.whatprovides(@rpmrequire)
      expect(x).to be_kind_of(Array)
      expect(x[0]).to eq(@rpm_v)
      expect(x[1]).to eq(@rpm_z)
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
    @stdin = double("STDIN", :nil_object => true)
    @stdout = double("STDOUT", :nil_object => true)

    @stdout_good = <<EOF
[option installonlypkgs] kernel kernel-bigmem kernel-enterprise
erlang-mochiweb 0 1.4.1 5.el5 x86_64 ['erlang-mochiweb = 1.4.1-5.el5', 'mochiweb = 1.4.1-5.el5'] i installed
zip 0 2.31 2.el5 x86_64 ['zip = 2.31-2.el5'] r base
zisofs-tools 0 1.0.6 3.2.2 x86_64 [] a extras
zlib 0 1.2.3 3 x86_64 ['zlib = 1.2.3-3', 'libz.so.1()(64bit)'] r base
zlib 0 1.2.3 3 i386 ['zlib = 1.2.3-3', 'libz.so.1'] r base
zlib-devel 0 1.2.3 3 i386 [] a extras
zlib-devel 0 1.2.3 3 x86_64 ['zlib-devel = 1.2.3-3'] r base
znc 0 0.098 1.el5 x86_64 [] a base
znc-devel 0 0.098 1.el5 i386 [] a extras
znc-devel 0 0.098 1.el5 x86_64 [] a base
znc-extra 0 0.098 1.el5 x86_64 [] a base
znc-modtcl 0 0.098 1.el5 x86_64 [] a base
znc-test.beta1 0 0.098 1.el5 x86_64 [] a extras
znc-test.test.beta1 0 0.098 1.el5 x86_64 [] a base
EOF
    @stdout_bad_type = <<EOF
zip 0 2.31 2.el5 x86_64 ['zip = 2.31-2.el5'] r base
zlib 0 1.2.3 3 x86_64 ['zlib = 1.2.3-3', 'libz.so.1()(64bit)'] c base
zlib-devel 0 1.2.3 3 i386 [] a extras
zlib-devel 0 1.2.3 3 x86_64 ['zlib-devel = 1.2.3-3'] bad installed
znc-modtcl 0 0.098 1.el5 x86_64 [] a base
EOF

    @stdout_bad_separators = <<EOF
zip 0 2.31 2.el5 x86_64 ['zip = 2.31-2.el5'] r base
zlib 0 1.2.3 3 x86_64 ['zlib = 1.2.3-3', 'libz.so.1()(64bit)'] i base bad
zlib-devel 0 1.2.3 3 i386 [] a extras
bad zlib-devel 0 1.2.3 3 x86_64 ['zlib-devel = 1.2.3-3'] i installed
znc-modtcl 0 0.098 1.el5 x86_64 [] a base bad
EOF

    @stdout_no_output = ""

    @stderr = <<EOF
yum-dump Config Error: File contains no section headers.
file: file://///etc/yum.repos.d/CentOS-Base.repo, line: 12
'qeqwewe\n'
EOF
    @status = double("Status", :exitstatus => 0, :stdin => @stdin, :stdout => @stdout_good, :stderr => @stderr)

    # new singleton each time
    Chef::Provider::Package::Yum::YumCache.reset_instance
    @yc = Chef::Provider::Package::Yum::YumCache.instance
    # load valid data
    allow(@yc).to receive(:shell_out!).and_return(@status)
  end

  describe "initialize" do
    it "should return a Chef::Provider::Package::Yum::YumCache object" do
      expect(@yc).to be_kind_of(Chef::Provider::Package::Yum::YumCache)
    end

    it "should register reload for start of Chef::Client runs" do
      Chef::Provider::Package::Yum::YumCache.reset_instance
      expect(Chef::Client).to receive(:when_run_starts) do |&b|
        expect(b).not_to be_nil
      end
      @yc = Chef::Provider::Package::Yum::YumCache.instance
    end
  end

  describe "refresh" do
    it "should implicitly call yum-dump.py only once by default after being instantiated" do
      expect(@yc).to receive(:shell_out!).once
      @yc.installed_version("zlib")
      @yc.reset
      @yc.installed_version("zlib")
    end

    it "should run yum-dump.py using the system python when next_refresh is for :all" do
      @yc.reload
      expect(@yc).to receive(:shell_out!).with(%r{^/usr/bin/python .*/yum-dump.py --options --installed-provides --yum-lock-timeout 30$}, :timeout=>Chef::Config[:yum_timeout])
      @yc.refresh
    end

    it "should run yum-dump.py with the installed flag when next_refresh is for :installed" do
      @yc.reload_installed
      expect(@yc).to receive(:shell_out!).with(%r{^/usr/bin/python .*/yum-dump.py --installed --yum-lock-timeout 30$}, :timeout=>Chef::Config[:yum_timeout])
      @yc.refresh
    end

    it "should run yum-dump.py with the all-provides flag when next_refresh is for :provides" do
      @yc.reload_provides
      expect(@yc).to receive(:shell_out!).with(%r{^/usr/bin/python .*/yum-dump.py --options --all-provides --yum-lock-timeout 30$}, :timeout=>Chef::Config[:yum_timeout])
      @yc.refresh
    end

    it "should pass extra_repo_control args to yum-dump.py" do
      @yc.enable_extra_repo_control("--enablerepo=foo --disablerepo=bar")
      expect(@yc).to receive(:shell_out!).with(%r{^/usr/bin/python .*/yum-dump.py --options --installed-provides --enablerepo=foo --disablerepo=bar --yum-lock-timeout 30$}, :timeout=>Chef::Config[:yum_timeout])
      @yc.refresh
    end

    it "should pass extra_repo_control args and configured yum lock timeout to yum-dump.py" do
      Chef::Config[:yum_lock_timeout] = 999
      @yc.enable_extra_repo_control("--enablerepo=foo --disablerepo=bar")
      expect(@yc).to receive(:shell_out!).with(%r{^/usr/bin/python .*/yum-dump.py --options --installed-provides --enablerepo=foo --disablerepo=bar --yum-lock-timeout 999$}, :timeout=>Chef::Config[:yum_timeout])
      @yc.refresh
    end

    it "should warn about invalid data with too many separators" do
      @status = double("Status", :exitstatus => 0, :stdin => @stdin, :stdout => @stdout_bad_separators, :stderr => @stderr)
      allow(@yc).to receive(:shell_out!).and_return(@status)
      expect(Chef::Log).to receive(:warn).exactly(3).times.with(%r{Problem parsing})
      @yc.refresh
    end

    it "should warn about invalid data with an incorrect type" do
      @status = double("Status", :exitstatus => 0, :stdin => @stdin, :stdout => @stdout_bad_type, :stderr => @stderr)
      allow(@yc).to receive(:shell_out!).and_return(@status)
      expect(Chef::Log).to receive(:warn).exactly(2).times.with(%r{Problem parsing})
      @yc.refresh
    end

    it "should warn about no output from yum-dump.py" do
      @status = double("Status", :exitstatus => 0, :stdin => @stdin, :stdout => @stdout_no_output, :stderr => @stderr)
      allow(@yc).to receive(:shell_out!).and_return(@status)
      expect(Chef::Log).to receive(:warn).exactly(1).times.with(%r{no output from yum-dump.py})
      @yc.refresh
    end

    it "should raise exception yum-dump.py exits with a non zero status" do
      @status = double("Status", :exitstatus => 1, :stdin => @stdin, :stdout => @stdout_no_output, :stderr => @stderr)
      allow(@yc).to receive(:shell_out!).and_return(@status)
      expect { @yc.refresh}.to raise_error(Chef::Exceptions::Package, %r{CentOS-Base.repo, line: 12})
    end

    it "should parse type 'i' into an installed state for a package" do
      expect(@yc.available_version("erlang-mochiweb")).to eq(nil)
      expect(@yc.installed_version("erlang-mochiweb")).not_to eq(nil)
    end

    it "should parse type 'a' into an available state for a package" do
      expect(@yc.available_version("znc")).not_to eq(nil)
      expect(@yc.installed_version("znc")).to eq(nil)
    end

    it "should parse type 'r' into an installed and available states for a package" do
      expect(@yc.available_version("zip")).not_to eq(nil)
      expect(@yc.installed_version("zip")).not_to eq(nil)
    end

    it "should parse installonlypkgs from yum-dump.py options output" do
      expect(@yc.allow_multi_install).to eq(%w{kernel kernel-bigmem kernel-enterprise})
    end
  end

  describe "installed_version" do
    it "should take one or two arguments" do
      expect { @yc.installed_version("zip") }.not_to raise_error
      expect { @yc.installed_version("zip", "i386") }.not_to raise_error
      expect { @yc.installed_version("zip", "i386", "extra") }.to raise_error(ArgumentError)
    end

    it "should return version-release for matching package regardless of arch" do
      expect(@yc.installed_version("zip", "x86_64")).to eq("2.31-2.el5")
      expect(@yc.installed_version("zip", nil)).to eq("2.31-2.el5")
    end

    it "should return version-release for matching package and arch" do
      expect(@yc.installed_version("zip", "x86_64")).to eq("2.31-2.el5")
      expect(@yc.installed_version("zisofs-tools", "i386")).to eq(nil)
    end

    it "should return nil for an unmatched package" do
      expect(@yc.installed_version(nil, nil)).to eq(nil)
      expect(@yc.installed_version("test1", nil)).to eq(nil)
      expect(@yc.installed_version("test2", "x86_64")).to eq(nil)
    end
  end

  describe "available_version" do
    it "should take one or two arguments" do
      expect { @yc.available_version("zisofs-tools") }.not_to raise_error
      expect { @yc.available_version("zisofs-tools", "i386") }.not_to raise_error
      expect { @yc.available_version("zisofs-tools", "i386", "extra") }.to raise_error(ArgumentError)
    end

    it "should return version-release for matching package regardless of arch" do
      expect(@yc.available_version("zip", "x86_64")).to eq("2.31-2.el5")
      expect(@yc.available_version("zip", nil)).to eq("2.31-2.el5")
    end

    it "should return version-release for matching package and arch" do
      expect(@yc.available_version("zip", "x86_64")).to eq("2.31-2.el5")
      expect(@yc.available_version("zisofs-tools", "i386")).to eq(nil)
    end

    it "should return nil for an unmatched package" do
      expect(@yc.available_version(nil, nil)).to eq(nil)
      expect(@yc.available_version("test1", nil)).to eq(nil)
      expect(@yc.available_version("test2", "x86_64")).to eq(nil)
    end
  end

  describe "version_available?" do
    it "should take two or three arguments" do
      expect { @yc.version_available?("zisofs-tools") }.to raise_error(ArgumentError)
      expect { @yc.version_available?("zisofs-tools", "1.0.6-3.2.2") }.not_to raise_error
      expect { @yc.version_available?("zisofs-tools", "1.0.6-3.2.2", "x86_64") }.not_to raise_error
    end

    it "should return true if our package-version-arch is available" do
      expect(@yc.version_available?("zisofs-tools", "1.0.6-3.2.2", "x86_64")).to eq(true)
    end

    it "should return true if our package-version, no arch, is available" do
      expect(@yc.version_available?("zisofs-tools", "1.0.6-3.2.2", nil)).to eq(true)
      expect(@yc.version_available?("zisofs-tools", "1.0.6-3.2.2")).to eq(true)
    end

    it "should return false if our package-version-arch isn't available" do
      expect(@yc.version_available?("zisofs-tools", "1.0.6-3.2.2", "pretend")).to eq(false)
      expect(@yc.version_available?("zisofs-tools", "pretend", "x86_64")).to eq(false)
      expect(@yc.version_available?("pretend", "1.0.6-3.2.2", "x86_64")).to eq(false)
    end

    it "should return false if our package-version, no arch, isn't available" do
      expect(@yc.version_available?("zisofs-tools", "pretend", nil)).to eq(false)
      expect(@yc.version_available?("zisofs-tools", "pretend")).to eq(false)
      expect(@yc.version_available?("pretend", "1.0.6-3.2.2")).to eq(false)
    end
  end

  describe "package_repository" do
    it "should take two or three arguments" do
      expect { @yc.package_repository("zisofs-tools") }.to raise_error(ArgumentError)
      expect { @yc.package_repository("zisofs-tools", "1.0.6-3.2.2") }.not_to raise_error
      expect { @yc.package_repository("zisofs-tools", "1.0.6-3.2.2", "x86_64") }.not_to raise_error
    end

    it "should return repoid for package-version-arch" do
      expect(@yc.package_repository("zlib-devel", "1.2.3-3", "i386")).to eq("extras")
      expect(@yc.package_repository("zlib-devel", "1.2.3-3", "x86_64")).to eq("base")
    end

    it "should return repoid for package-version, no arch" do
      expect(@yc.package_repository("zisofs-tools", "1.0.6-3.2.2", nil)).to eq("extras")
      expect(@yc.package_repository("zisofs-tools", "1.0.6-3.2.2")).to eq("extras")
    end

    it "should return nil when no match for package-version-arch" do
      expect(@yc.package_repository("zisofs-tools", "1.0.6-3.2.2", "pretend")).to eq(nil)
      expect(@yc.package_repository("zisofs-tools", "pretend", "x86_64")).to eq(nil)
      expect(@yc.package_repository("pretend", "1.0.6-3.2.2", "x86_64")).to eq(nil)
    end

    it "should return nil when no match for package-version, no arch" do
      expect(@yc.package_repository("zisofs-tools", "pretend", nil)).to eq(nil)
      expect(@yc.package_repository("zisofs-tools", "pretend")).to eq(nil)
      expect(@yc.package_repository("pretend", "1.0.6-3.2.2")).to eq(nil)
    end
  end

  describe "reset" do
    it "should empty the installed and available packages RPMDb" do
      expect(@yc.available_version("zip", "x86_64")).to eq("2.31-2.el5")
      expect(@yc.installed_version("zip", "x86_64")).to eq("2.31-2.el5")
      @yc.reset
      expect(@yc.available_version("zip", "x86_64")).to eq(nil)
      expect(@yc.installed_version("zip", "x86_64")).to eq(nil)
    end
  end

  describe "package_available?" do
    it "should return true a package name is available" do
      expect(@yc.package_available?("zisofs-tools")).to eq(true)
      expect(@yc.package_available?("moo")).to eq(false)
      expect(@yc.package_available?(nil)).to eq(false)
    end

    it "should return true a package name + arch is available" do
      expect(@yc.package_available?("zlib-devel.i386")).to eq(true)
      expect(@yc.package_available?("zisofs-tools.x86_64")).to eq(true)
      expect(@yc.package_available?("znc-test.beta1.x86_64")).to eq(true)
      expect(@yc.package_available?("znc-test.beta1")).to eq(true)
      expect(@yc.package_available?("znc-test.test.beta1")).to eq(true)
      expect(@yc.package_available?("moo.i386")).to eq(false)
      expect(@yc.package_available?("zisofs-tools.beta")).to eq(false)
      expect(@yc.package_available?("znc-test.test")).to eq(false)
    end
  end

  describe "enable_extra_repo_control" do
    it "should set @extra_repo_control to arg" do
      @yc.enable_extra_repo_control("--enablerepo=test")
      expect(@yc.extra_repo_control).to eq("--enablerepo=test")
    end

    it "should call reload once when set to flag cache for update" do
      expect(@yc).to receive(:reload).once
      @yc.enable_extra_repo_control("--enablerepo=test")
      @yc.enable_extra_repo_control("--enablerepo=test")
    end
  end

  describe "disable_extra_repo_control" do
    it "should set @extra_repo_control to nil" do
      @yc.enable_extra_repo_control("--enablerepo=test")
      @yc.disable_extra_repo_control
      expect(@yc.extra_repo_control).to eq(nil)
    end

    it "should call reload once when cleared to flag cache for update" do
      expect(@yc).to receive(:reload).once
      @yc.enable_extra_repo_control("--enablerepo=test")
      expect(@yc).to receive(:reload).once
      @yc.disable_extra_repo_control
      @yc.disable_extra_repo_control
    end
  end

end
