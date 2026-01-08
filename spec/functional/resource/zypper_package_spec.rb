#
# Author:: Dheeraj Dubey (<dheeraj.dubey@msystechnologies.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require "chef/mixin/shell_out"

describe Chef::Resource::ZypperPackage, :requires_root, :suse_only do
  include Chef::Mixin::ShellOut

  # NOTE: every single test here needs to explicitly call preinstall.

  def preinstall(*rpms)
    rpms.each do |rpm|
      shell_out!("rpm -ivh #{CHEF_SPEC_ASSETS}/zypprepo/#{rpm}")
    end
  end

  before(:each) do
    File.open("/etc/zypp/repos.d/chef-zypp-localtesting.repo", "w+") do |f|
      f.write <<~EOF
        [chef-zypp-localtesting]
        name=Chef zypper spec testing repo
        baseurl=file://#{CHEF_SPEC_ASSETS}/zypprepo
        enable=1
        gpgcheck=0
      EOF
    end
    shell_out!("rpm -qa --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' chef_rpm | xargs -r rpm -e")
    # next line is useful cleanup if you happen to have been testing zypper func tests on the same box and
    # have some zypper garbage left around
    # FileUtils.rm_f "/etc/zypp/repos.d/chef-zypp-localtesting.repo"
  end

  after(:all) do
    shell_out!("rpm -qa --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' chef_rpm | xargs -r rpm -e")
    FileUtils.rm_f "/etc/zypp/repos.d/chef-zypp-localtesting.repo"
  end

  let(:run_context) do
    Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
  end

  let(:package_name) { "chef_rpm" }
  let(:zypper_package) do
    r = Chef::Resource::ZypperPackage.new(package_name, run_context)
    r.global_options("--no-gpg-checks")
    r
  end

  def pkg_arch
    ohai[:kernel][:machine]
  end

  context "installing a package" do
    after { remove_package }
    it "installs the latest version" do
      zypper_package.run_action(:install)
      expect(zypper_package.updated_by_last_action?).to be true
      expect(shell_out("rpm -q --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' chef_rpm").stdout.chomp).to match("^chef_rpm-1.10-1.#{pkg_arch}$")
    end

    it "install package with source argument" do
      zypper_package.source = "#{CHEF_SPEC_ASSETS}/zypprepo/chef_rpm-1.10-1.#{pkg_arch}.rpm"
      zypper_package.run_action(:install)
      expect(zypper_package.updated_by_last_action?).to be true
      expect(shell_out("rpm -q --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' chef_rpm").stdout.chomp).to match("^chef_rpm-1.10-1.#{pkg_arch}$")
    end

    it "raises an error when passed a source that does not exist" do
      zypper_package.source = "#{CHEF_SPEC_ASSETS}/false/zypprepo/chef_rpm-1.10-1.#{pkg_arch}.rpm"
      expect { zypper_package.run_action(:install) }.to raise_error(Mixlib::ShellOut::ShellCommandFailed)
    end

    it "does not install if the package is installed" do
      preinstall("chef_rpm-1.10-1.#{pkg_arch}.rpm")
      zypper_package.run_action(:install)
      expect(zypper_package.updated_by_last_action?).to be false
      expect(shell_out("rpm -q --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' chef_rpm").stdout.chomp).to match("^chef_rpm-1.10-1.#{pkg_arch}$")
    end

    it "does not install twice" do
      zypper_package.run_action(:install)
      expect(zypper_package.updated_by_last_action?).to be true
      expect(shell_out("rpm -q --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' chef_rpm").stdout.chomp).to match("^chef_rpm-1.10-1.#{pkg_arch}$")
      zypper_package.run_action(:install)
      expect(zypper_package.updated_by_last_action?).to be false
      expect(shell_out("rpm -q --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' chef_rpm").stdout.chomp).to match("^chef_rpm-1.10-1.#{pkg_arch}$")
    end

    it "does not install if the prior version package is installed" do
      preinstall("chef_rpm-1.2-1.#{pkg_arch}.rpm")
      zypper_package.run_action(:install)
      expect(zypper_package.updated_by_last_action?).to be false
      expect(shell_out("rpm -q --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' chef_rpm").stdout.chomp).to match("^chef_rpm-1.2-1.#{pkg_arch}$")
    end

    it "multipackage installs which result in nils from the superclass" do
      # this looks weird, it tests an internal condition of the allow_nils behavior where the arrays passed to install_package will have
      # nil values, and ensures that doesn't wind up creating weirdness in the resulting shell_out that causes it to fail
      preinstall("chef_rpm-1.2-1.#{pkg_arch}.rpm")
      zypper_package.package_name(%w{chef_rpm chef_rpm})
      zypper_package.version(["1.2", "1.10"])
      zypper_package.run_action(:install)
      expect(zypper_package.updated_by_last_action?).to be true
      expect(shell_out("rpm -q --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' chef_rpm").stdout.chomp).to match("^chef_rpm-1.10-1.#{pkg_arch}$")
    end
  end

  context "with versions" do
    it "works with a version" do
      zypper_package.package_name("chef_rpm")
      zypper_package.version("1.10")
      zypper_package.run_action(:install)
      expect(zypper_package.updated_by_last_action?).to be true
      expect(shell_out("rpm -q --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' chef_rpm").stdout.chomp).to match("^chef_rpm-1.10-1.#{pkg_arch}$")
    end

    it "works with an older version" do
      zypper_package.package_name("chef_rpm")
      zypper_package.version("1.2")
      zypper_package.run_action(:install)
      expect(zypper_package.updated_by_last_action?).to be true
      expect(shell_out("rpm -q --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' chef_rpm").stdout.chomp).to match("^chef_rpm-1.2-1.#{pkg_arch}$")
    end

    it "works with version and release" do
      zypper_package.package_name("chef_rpm")
      zypper_package.version("1.2-1")
      zypper_package.run_action(:install)
      expect(zypper_package.updated_by_last_action?).to be true
      expect(shell_out("rpm -q --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' chef_rpm").stdout.chomp).to match("^chef_rpm-1.2-1.#{pkg_arch}$")
    end

    it "downgrades when the installed version is higher than the package_name version" do
      preinstall("chef_rpm-1.10-1.#{pkg_arch}.rpm")
      zypper_package.allow_downgrade true
      zypper_package.package_name("chef_rpm")
      zypper_package.version("1.2-1")
      zypper_package.run_action(:install)
      expect(zypper_package.updated_by_last_action?).to be true
      expect(shell_out("rpm -q --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' chef_rpm").stdout.chomp).to match("^chef_rpm-1.2-1.#{pkg_arch}$")
    end
  end

  describe ":remove" do
    context "vanilla use case" do
      let(:package_name) { "chef_rpm" }
      it "does nothing if the package is not installed" do
        zypper_package.run_action(:remove)
        expect(zypper_package.updated_by_last_action?).to be false
        expect(shell_out("rpm -q --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' chef_rpm").stdout.chomp).to match("^package chef_rpm is not installed$")
      end

      it "removes the package if the package is installed" do
        preinstall("chef_rpm-1.10-1.#{pkg_arch}.rpm")
        zypper_package.run_action(:remove)
        expect(zypper_package.updated_by_last_action?).to be true
        expect(shell_out("rpm -q --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' chef_rpm").stdout.chomp).to match("^package chef_rpm is not installed$")
      end

      it "does not remove the package twice" do
        preinstall("chef_rpm-1.10-1.#{pkg_arch}.rpm")
        zypper_package.run_action(:remove)
        expect(zypper_package.updated_by_last_action?).to be true
        expect(shell_out("rpm -q --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' chef_rpm").stdout.chomp).to match("^package chef_rpm is not installed$")
        zypper_package.run_action(:remove)
        expect(zypper_package.updated_by_last_action?).to be false
        expect(shell_out("rpm -q --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' chef_rpm").stdout.chomp).to match("^package chef_rpm is not installed$")
      end

      it "removes the package if the prior version package is installed" do
        preinstall("chef_rpm-1.2-1.#{pkg_arch}.rpm")
        zypper_package.run_action(:remove)
        expect(zypper_package.updated_by_last_action?).to be true
        expect(shell_out("rpm -q --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' chef_rpm").stdout.chomp).to match("^package chef_rpm is not installed$")
      end

      context "Package doesn't exist" do
        let(:package_name) { "nonexistent_repo" }
        it "does nothing if the package is not installed" do
          zypper_package.run_action(:remove)
          expect(zypper_package.updated_by_last_action?).to be false
        end

      end
    end

    context "with no available version" do
      it "works when a package is installed" do
        FileUtils.rm_f "/etc/zypp/repos.d/chef-zypp-localtesting.repo"
        preinstall("chef_rpm-1.2-1.#{pkg_arch}.rpm")
        zypper_package.run_action(:remove)
        expect(zypper_package.updated_by_last_action?).to be true
        expect(shell_out("rpm -q --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' chef_rpm").stdout.chomp).to match("^package chef_rpm is not installed$")
      end

      it "is idempotent when a package isn't installed" do
        FileUtils.rm_f "/etc/zypp/repos.d/chef-zypp-localtesting.repo"
        zypper_package.run_action(:remove)
        expect(zypper_package.updated_by_last_action?).to be false
        expect(shell_out("rpm -q --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' chef_rpm").stdout.chomp).to match("^package chef_rpm is not installed$")
      end
    end
  end

  describe ":lock and :unlock" do
    before(:each) do
      shell_out("zypper removelock chef_rpm") # will exit with error when nothing is locked, we don't care
    end

    it "locks an rpm" do
      zypper_package.package_name("chef_rpm")
      zypper_package.run_action(:lock)
      expect(zypper_package.updated_by_last_action?).to be true
      expect(shell_out("zypper locks | grep chef_rpm").stdout.chomp).to match("chef_rpm")
    end

    it "does not lock if its already locked" do
      shell_out!("zypper addlock chef_rpm")
      zypper_package.package_name("chef_rpm")
      zypper_package.run_action(:lock)
      expect(zypper_package.updated_by_last_action?).to be false
      expect(shell_out("zypper locks | grep chef_rpm").stdout.chomp).to match("chef_rpm")
    end

    it "unlocks an rpm" do
      shell_out!("zypper addlock chef_rpm")
      zypper_package.package_name("chef_rpm")
      zypper_package.run_action(:unlock)
      expect(zypper_package.updated_by_last_action?).to be true
      expect(shell_out("zypper locks | grep chef_rpm").stdout.chomp).not_to match("chef_rpm")
    end

    it "does not unlock an already locked rpm" do
      zypper_package.package_name("chef_rpm")
      zypper_package.run_action(:unlock)
      expect(zypper_package.updated_by_last_action?).to be false
      expect(shell_out("zypper locks | grep chef_rpm").stdout.chomp).not_to match("chef_rpm")
    end

    it "check that we can lock based on provides" do
      zypper_package.package_name("chef_rpm_provides")
      zypper_package.run_action(:lock)
      expect(zypper_package.updated_by_last_action?).to be true
      expect(shell_out("zypper locks | grep chef_rpm_provides").stdout.chomp).to match("chef_rpm_provides")
    end

    it "check that we can unlock based on provides" do
      shell_out!("zypper addlock chef_rpm_provides")
      zypper_package.package_name("chef_rpm_provides")
      zypper_package.run_action(:unlock)
      expect(zypper_package.updated_by_last_action?).to be true
      expect(shell_out("zypper locks | grep chef_rpm_provides").stdout.chomp).not_to match("chef_rpm_provides")
    end
  end

  def remove_package
    pkg_to_remove = Chef::Resource::ZypperPackage.new(package_name, run_context)
    pkg_to_remove.run_action(:remove)
  end
end
