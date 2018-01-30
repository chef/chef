#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

require "spec_helper"
require "ostruct"

describe Chef::Provider::Package::Apt do
  # XXX: sorry this is ugly and was done quickly to get 12.0.2 out, this file needs a rewrite to use
  # let blocks and shared examples
  [ Chef::Resource::Package, Chef::Resource::AptPackage ].each do |resource_klass|
    describe "when the new_resource is a #{resource_klass}" do

      before(:each) do
        @node = Chef::Node.new
        @events = Chef::EventDispatch::Dispatcher.new
        @run_context = Chef::RunContext.new(@node, {}, @events)
        @new_resource = resource_klass.new("irssi", @run_context)

        @status = double("Status", :exitstatus => 0)
        @provider = Chef::Provider::Package::Apt.new(@new_resource, @run_context)
        @stdin = StringIO.new
        @stdout = <<-PKG_STATUS
irssi:
  Installed: (none)
  Candidate: 0.8.14-1ubuntu4
  Version table:
     0.8.14-1ubuntu4 0
        500 http://us.archive.ubuntu.com/ubuntu/ lucid/main Packages
        PKG_STATUS
        @stderr = ""
        @shell_out = OpenStruct.new(:stdout => @stdout, :stdin => @stdin, :stderr => @stderr, :status => @status, :exitstatus => 0)
        @timeout = 900
      end

      describe "when loading current resource" do

        it "should create a current resource with the name of the new_resource" do
          expect(@provider).to receive(:shell_out!).with(
            "apt-cache", "policy", @new_resource.package_name,
            :env => { "DEBIAN_FRONTEND" => "noninteractive" },
            :timeout => @timeout
          ).and_return(@shell_out)
          @provider.load_current_resource

          current_resource = @provider.current_resource
          expect(current_resource).to be_a(Chef::Resource::Package)
          expect(current_resource.name).to eq("irssi")
          expect(current_resource.package_name).to eq("irssi")
          expect(current_resource.version).to eql([nil])
        end

        it "should set the installed version if package has one" do
          @stdout.replace(<<-INSTALLED)
sudo:
  Installed: 1.7.2p1-1ubuntu5.3
  Candidate: 1.7.2p1-1ubuntu5.3
  Version table:
 *** 1.7.2p1-1ubuntu5.3 0
        500 http://us.archive.ubuntu.com/ubuntu/ lucid-updates/main Packages
        500 http://security.ubuntu.com/ubuntu/ lucid-security/main Packages
        100 /var/lib/dpkg/status
     1.7.2p1-1ubuntu5 0
        500 http://us.archive.ubuntu.com/ubuntu/ lucid/main Packages
          INSTALLED
          expect(@provider).to receive(:shell_out!).and_return(@shell_out)
          @provider.load_current_resource
          expect(@provider.current_resource.version).to eq(["1.7.2p1-1ubuntu5.3"])
          expect(@provider.candidate_version).to eql(["1.7.2p1-1ubuntu5.3"])
        end

        # it is the superclasses responsibility to throw most exceptions
        it "if the package does not exist in the cache sets installed + candidate version to nil" do
          @new_resource.package_name("conic-smarms")
          policy_out = <<-POLICY_STDOUT
N: Unable to locate package conic-smarms
          POLICY_STDOUT
          policy = double(:stdout => policy_out, :exitstatus => 0)
          expect(@provider).to receive(:shell_out!).with(
            "apt-cache", "policy", "conic-smarms",
            :env => { "DEBIAN_FRONTEND" => "noninteractive" },
            :timeout => @timeout
          ).and_return(policy)
          showpkg_out = <<-SHOWPKG_STDOUT
N: Unable to locate package conic-smarms
          SHOWPKG_STDOUT
          showpkg = double(:stdout => showpkg_out, :exitstatus => 0)
          expect(@provider).to receive(:shell_out!).with(
            "apt-cache", "showpkg", "conic-smarms",
            :env => { "DEBIAN_FRONTEND" => "noninteractive" },
            :timeout => @timeout
          ).and_return(showpkg)
          @provider.load_current_resource
        end

        # libmysqlclient-dev is a real package in newer versions of debian + ubuntu
        # list of virtual packages: http://www.debian.org/doc/packaging-manuals/virtual-package-names-list.txt
        it "should not install the virtual package there is a single provider package and it is installed" do
          @new_resource.package_name("libmysqlclient15-dev")
          virtual_package_out = <<-VPKG_STDOUT
libmysqlclient15-dev:
  Installed: (none)
  Candidate: (none)
  Version table:
          VPKG_STDOUT
          virtual_package = double(:stdout => virtual_package_out, :exitstatus => 0)
          expect(@provider).to receive(:shell_out!).with(
            "apt-cache", "policy", "libmysqlclient15-dev",
            :env => { "DEBIAN_FRONTEND" => "noninteractive" },
            :timeout => @timeout
          ).and_return(virtual_package)
          showpkg_out = <<-SHOWPKG_STDOUT
Package: libmysqlclient15-dev
Versions:

Reverse Depends:
  libmysqlclient-dev,libmysqlclient15-dev
  libmysqlclient-dev,libmysqlclient15-dev
  libmysqlclient-dev,libmysqlclient15-dev
  libmysqlclient-dev,libmysqlclient15-dev
  libmysqlclient-dev,libmysqlclient15-dev
  libmysqlclient-dev,libmysqlclient15-dev
Dependencies:
Provides:
Reverse Provides:
libmysqlclient-dev 5.1.41-3ubuntu12.7
libmysqlclient-dev 5.1.41-3ubuntu12.10
libmysqlclient-dev 5.1.41-3ubuntu12
          SHOWPKG_STDOUT
          showpkg = double(:stdout => showpkg_out, :exitstatus => 0)
          expect(@provider).to receive(:shell_out!).with(
            "apt-cache", "showpkg", "libmysqlclient15-dev",
            :env => { "DEBIAN_FRONTEND" => "noninteractive" },
            :timeout => @timeout
          ).and_return(showpkg)
          real_package_out = <<-RPKG_STDOUT
libmysqlclient-dev:
  Installed: 5.1.41-3ubuntu12.10
  Candidate: 5.1.41-3ubuntu12.10
  Version table:
 *** 5.1.41-3ubuntu12.10 0
        500 http://us.archive.ubuntu.com/ubuntu/ lucid-updates/main Packages
        100 /var/lib/dpkg/status
     5.1.41-3ubuntu12.7 0
        500 http://security.ubuntu.com/ubuntu/ lucid-security/main Packages
     5.1.41-3ubuntu12 0
        500 http://us.archive.ubuntu.com/ubuntu/ lucid/main Packages
          RPKG_STDOUT
          real_package = double(:stdout => real_package_out, :exitstatus => 0)
          expect(@provider).to receive(:shell_out!).with(
            "apt-cache", "policy", "libmysqlclient-dev",
            :env => { "DEBIAN_FRONTEND" => "noninteractive" },
            :timeout => @timeout
          ).and_return(real_package)
          @provider.load_current_resource
        end

        it "should raise an exception if you specify a virtual package with multiple provider packages" do
          @new_resource.package_name("mp3-decoder")
          virtual_package_out = <<-VPKG_STDOUT
mp3-decoder:
  Installed: (none)
  Candidate: (none)
  Version table:
          VPKG_STDOUT
          virtual_package = double(:stdout => virtual_package_out, :exitstatus => 0)
          expect(@provider).to receive(:shell_out!).with(
            "apt-cache", "policy", "mp3-decoder",
            :env => { "DEBIAN_FRONTEND" => "noninteractive" },
            :timeout => @timeout
          ).and_return(virtual_package)
          showpkg_out = <<-SHOWPKG_STDOUT
Package: mp3-decoder
Versions:

Reverse Depends:
  nautilus,mp3-decoder
  vux,mp3-decoder
  plait,mp3-decoder
  ecasound,mp3-decoder
  nautilus,mp3-decoder
Dependencies:
Provides:
Reverse Provides:
vlc-nox 1.0.6-1ubuntu1.8
vlc 1.0.6-1ubuntu1.8
vlc-nox 1.0.6-1ubuntu1
vlc 1.0.6-1ubuntu1
opencubicplayer 1:0.1.17-2
mpg321 0.2.10.6
mpg123 1.12.1-0ubuntu1
          SHOWPKG_STDOUT
          showpkg = double(:stdout => showpkg_out, :exitstatus => 0)
          expect(@provider).to receive(:shell_out!).with(
            "apt-cache", "showpkg", "mp3-decoder",
            :env => { "DEBIAN_FRONTEND" => "noninteractive" },
            :timeout => @timeout
          ).and_return(showpkg)
          expect { @provider.load_current_resource }.to raise_error(Chef::Exceptions::Package)
        end

        it "should run apt-cache policy with the default_release option, if there is one on the resource" do
          @new_resource = Chef::Resource::AptPackage.new("irssi", @run_context)
          @provider = Chef::Provider::Package::Apt.new(@new_resource, @run_context)

          @new_resource.default_release("lenny-backports")
          @new_resource.provider(nil)
          expect(@provider).to receive(:shell_out!).with(
            "apt-cache", "-o", "APT::Default-Release=lenny-backports", "policy", "irssi",
            :env => { "DEBIAN_FRONTEND" => "noninteractive" },
            :timeout => @timeout
          ).and_return(@shell_out)
          @provider.load_current_resource
        end

        it "raises an exception if a source is specified (CHEF-5113)" do
          @new_resource.source "pluto"
          expect(@provider).to receive(:shell_out!).with(
            "apt-cache", "policy", @new_resource.package_name,
            :env => { "DEBIAN_FRONTEND" => "noninteractive" } ,
            :timeout => @timeout
          ).and_return(@shell_out)
          expect { @provider.run_action(:install) }.to raise_error(Chef::Exceptions::Package)
        end
      end

      context "after loading the current resource" do
        before do
          @current_resource = resource_klass.new("irssi", @run_context)
          @provider.current_resource = @current_resource
          allow(@provider).to receive(:package_data).and_return({
            "irssi" => {
              virtual: false,
              candidate_version: "0.8.12-7",
              installed_version: nil,
            },
            "libmysqlclient15-dev" => {
              virtual: true,
              candidate_version: nil,
              installed_version: nil,
            },
          })
        end

        describe "install_package" do
          it "should run apt-get install with the package name and version" do
            expect(@provider).to receive(:shell_out!). with(
              "apt-get", "-q", "-y", "-o", "Dpkg::Options::=--force-confdef", "-o", "Dpkg::Options::=--force-confold", "install", "irssi=0.8.12-7",
              :env => { "DEBIAN_FRONTEND" => "noninteractive" },
              :timeout => @timeout
            )
            @provider.install_package(["irssi"], ["0.8.12-7"])
          end

          # FIXME make this test pass before merging
          skip "should run apt-get install with the package name and version and options if specified" do
            expect(@provider).to receive(:shell_out!).with(
              "apt-get", "-q", "-y", "-o", "Dpkg::Options::=--force-confdef", "-o", "Dpkg::Options::=--force-confold", "--force-yes", "install", "irssi=0.8.12-7",
              :env => { "DEBIAN_FRONTEND" => "noninteractive" },
              :timeout => @timeout
            )
            @new_resource.options("--force-yes")
            @provider.install_package(["irssi"], ["0.8.12-7"])
          end

          it "should run apt-get install with the package name and version and default_release if there is one and provider is explicitly defined" do
            @new_resource = nil
            @new_resource = Chef::Resource::AptPackage.new("irssi", @run_context)
            @new_resource.default_release("lenny-backports")
            @new_resource.provider = nil
            @provider.new_resource = @new_resource

            expect(@provider).to receive(:shell_out!).with(
              "apt-get", "-q", "-y", "-o", "Dpkg::Options::=--force-confdef", "-o", "Dpkg::Options::=--force-confold", "-o", "APT::Default-Release=lenny-backports", "install", "irssi=0.8.12-7",
              :env => { "DEBIAN_FRONTEND" => "noninteractive" },
              :timeout => @timeout
            )

            @provider.install_package(["irssi"], ["0.8.12-7"])
          end

          # FIXME make pass before merging
          skip "should run apt-get install with the package name and quotes options if specified" do
            expect(@provider).to receive(:shell_out!).with(
              "apt-get", "-q", "-y", "--force-yes", "-o", "Dpkg::Options::=--force-confdef", "-o", "Dpkg::Options::=--force-confnew", "install", "irssi=0.8.12-7",
              :env => { "DEBIAN_FRONTEND" => "noninteractive" },
              :timeout => @timeout
            )
            @new_resource.options('--force-yes -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew"')
            @provider.install_package(["irssi"], ["0.8.12-7"])
          end
        end

        describe resource_klass, "upgrade_package" do

          it "should run install_package with the name and version" do
            expect(@provider).to receive(:install_package).with(["irssi"], ["0.8.12-7"])
            @provider.upgrade_package(["irssi"], ["0.8.12-7"])
          end
        end

        describe resource_klass, "remove_package" do

          it "should run apt-get remove with the package name" do
            expect(@provider).to receive(:shell_out!).with(
              "apt-get", "-q", "-y", "remove", "irssi",
              :env => { "DEBIAN_FRONTEND" => "noninteractive" },
              :timeout => @timeout
            )
            @provider.remove_package(["irssi"], ["0.8.12-7"])
          end

          it "should run apt-get remove with the package name and options if specified" do
            expect(@provider).to receive(:shell_out!).with(
              "apt-get", "-q", "-y", "--force-yes", "remove", "irssi",
              :env => { "DEBIAN_FRONTEND" => "noninteractive" },
              :timeout => @timeout
            )
            @new_resource.options("--force-yes")

            @provider.remove_package(["irssi"], ["0.8.12-7"])
          end
        end

        describe "when purging a package" do

          it "should run apt-get purge with the package name" do
            expect(@provider).to receive(:shell_out!).with(
              "apt-get", "-q", "-y", "purge", "irssi",
              :env => { "DEBIAN_FRONTEND" => "noninteractive" },
              :timeout => @timeout
            )
            @provider.purge_package(["irssi"], ["0.8.12-7"])
          end

          it "should run apt-get purge with the package name and options if specified" do
            expect(@provider).to receive(:shell_out!).with(
              "apt-get", "-q", "-y", "--force-yes", "purge", "irssi",
              :env => { "DEBIAN_FRONTEND" => "noninteractive" },
              :timeout => @timeout
            )
            @new_resource.options("--force-yes")

            @provider.purge_package(["irssi"], ["0.8.12-7"])
          end
        end

        describe "when preseeding a package" do
          before(:each) do
            allow(@provider).to receive(:get_preseed_file).and_return("/tmp/irssi-0.8.12-7.seed")
          end

          it "should get the full path to the preseed response file" do
            file = "/tmp/irssi-0.8.12-7.seed"

            expect(@provider).to receive(:shell_out!).with(
              "debconf-set-selections", "/tmp/irssi-0.8.12-7.seed",
              :env => { "DEBIAN_FRONTEND" => "noninteractive" },
              :timeout => @timeout
            )

            @provider.preseed_package(file)
          end

          it "should run debconf-set-selections on the preseed file if it has changed" do
            expect(@provider).to receive(:shell_out!).with(
              "debconf-set-selections", "/tmp/irssi-0.8.12-7.seed",
              :env => { "DEBIAN_FRONTEND" => "noninteractive" },
              :timeout => @timeout
            )
            file = @provider.get_preseed_file("irssi", "0.8.12-7")
            @provider.preseed_package(file)
          end

          it "should not run debconf-set-selections if the preseed file has not changed" do
            allow(@provider).to receive(:check_all_packages_state)
            @current_resource.version "0.8.11"
            @new_resource.response_file "/tmp/file"
            allow(@provider).to receive(:get_preseed_file).and_return(false)
            expect(@provider).not_to receive(:shell_out!)
            @provider.run_action(:reconfig)
          end
        end

        describe "when reconfiguring a package" do
          it "should run dpkg-reconfigure package" do
            expect(@provider).to receive(:shell_out!).with(
              "dpkg-reconfigure", "irssi",
              :env => { "DEBIAN_FRONTEND" => "noninteractive" },
              :timeout => @timeout
            )
            @provider.reconfig_package("irssi", "0.8.12-7")
          end
        end

        describe "when locking a package" do
          it "should run apt-mark hold package" do
            expect(@provider).to receive(:shell_out!).with(
              "apt-mark", "hold", "irssi",
              :env => { "DEBIAN_FRONTEND" => "noninteractive" },
              :timeout => @timeout
            )
            @provider.lock_package("irssi", "0.8.12-7")
          end
          it "should not lock if the package is already locked" do
            allow(@provider).to receive(:shell_out_compact_timeout!).with(
              "apt-mark", "showhold"
            ).and_return(instance_double(
              Mixlib::ShellOut, stdout: "irssi")
            )
            expect(Chef::Log).to receive(:debug).with("#{@provider.new_resource} is already locked")

            @provider.new_resource.package_name = ["irssi"]
            @provider.action_lock
          end
        end

        describe "when unlocking a package" do
          it "should run apt-mark unhold package" do
            expect(@provider).to receive(:shell_out!).with(
              "apt-mark", "unhold", "irssi",
              :env => { "DEBIAN_FRONTEND" => "noninteractive" },
              :timeout => @timeout
            )
            @provider.unlock_package("irssi", "0.8.12-7")
          end
          it "should not unlock if the package is already unlocked" do
            allow(@provider).to receive(:shell_out_compact_timeout!).with(
              "apt-mark", "showhold"
            ).and_return(instance_double(
              Mixlib::ShellOut, stdout: "")
            )
            expect(Chef::Log).to receive(:debug).with("#{@provider.new_resource} is already unlocked")

            @provider.new_resource.package_name = ["irssi"]
            @provider.action_unlock
          end
        end

        describe "when installing a virtual package" do
          it "should install the package without specifying a version" do
            @provider.package_data["libmysqlclient15-dev"][:virtual] = true
            expect(@provider).to receive(:shell_out!).with(
              "apt-get", "-q", "-y", "-o", "Dpkg::Options::=--force-confdef", "-o", "Dpkg::Options::=--force-confold", "install", "libmysqlclient15-dev",
              :env => { "DEBIAN_FRONTEND" => "noninteractive" },
              :timeout => @timeout
            )
            @provider.install_package(["libmysqlclient15-dev"], ["not_a_real_version"])
          end
        end

        describe "when removing a virtual package" do
          it "should remove the resolved name instead of the virtual package name" do
            expect(@provider).to receive(:resolve_virtual_package_name).with("libmysqlclient15-dev").and_return("libmysqlclient-dev")
            expect(@provider).to receive(:shell_out!).with(
              "apt-get", "-q", "-y", "remove", "libmysqlclient-dev",
              :env => { "DEBIAN_FRONTEND" => "noninteractive" },
              :timeout => @timeout
            )
            @provider.remove_package(["libmysqlclient15-dev"], ["not_a_real_version"])
          end
        end

        describe "when purging a virtual package" do
          it "should purge the resolved name instead of the virtual package name" do
            expect(@provider).to receive(:resolve_virtual_package_name).with("libmysqlclient15-dev").and_return("libmysqlclient-dev")
            expect(@provider).to receive(:shell_out!).with(
              "apt-get", "-q", "-y", "purge", "libmysqlclient-dev",
              :env => { "DEBIAN_FRONTEND" => "noninteractive" },
              :timeout => @timeout
            )
            @provider.purge_package(["libmysqlclient15-dev"], ["not_a_real_version"])
          end
        end

        describe "when installing multiple packages" do
          it "can install a virtual package followed by a non-virtual package" do
            # https://github.com/chef/chef/issues/2914
            expect(@provider).to receive(:shell_out!).with(
              "apt-get", "-q", "-y", "-o", "Dpkg::Options::=--force-confdef", "-o", "Dpkg::Options::=--force-confold", "install", "libmysqlclient15-dev", "irssi=0.8.12-7",
              :env => { "DEBIAN_FRONTEND" => "noninteractive" },
              :timeout => @timeout
            )
            @provider.install_package(["libmysqlclient15-dev", "irssi"], ["not_a_real_version", "0.8.12-7"])
          end
        end

        describe "#action_install" do
          it "should run dpkg to compare versions if an existing version is installed" do
            allow(@provider).to receive(:get_current_versions).and_return("1.4.0")
            allow(@new_resource).to receive(:allow_downgrade).and_return(false)
            expect(@provider).to receive(:shell_out_compact_timeout).with(
              "dpkg", "--compare-versions", "1.4.0", "gt", "0.8.12-7"
            ).and_return(double(error?: false))
            @provider.run_action(:upgrade)
          end

          it "should install the package if the installed version is older" do
            allow(@provider).to receive(:get_current_versions).and_return("0.4.0")
            allow(@new_resource).to receive(:allow_downgrade).and_return(false)
            expect(@provider).to receive(:version_compare).and_return(-1)
            expect(@provider).to receive(:shell_out!).with(
              "apt-get", "-q", "-y", "install", "irssi=0.8.12-7",
              :env => { "DEBIAN_FRONTEND" => "noninteractive" },
              :timeout => @timeout
            )
            @provider.run_action(:upgrade)
          end

          it "should not compare versions if an existing version is not installed" do
            allow(@provider).to receive(:get_current_versions).and_return(nil)
            allow(@new_resource).to receive(:allow_downgrade).and_return(false)
            expect(@provider).not_to receive(:version_compare)
            expect(@provider).to receive(:shell_out!).with(
              "apt-get", "-q", "-y", "install", "irssi=0.8.12-7",
              :env => { "DEBIAN_FRONTEND" => "noninteractive" },
              :timeout => @timeout
            )
            @provider.run_action(:upgrade)
          end
        end
      end
    end
  end
end
