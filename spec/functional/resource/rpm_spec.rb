#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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
require "functional/resource/base"
require "chef/mixin/shell_out"

# run this test only for following platforms.
exclude_test = !%w{aix rhel fedora suse}.include?(ohai[:platform_family])
describe Chef::Resource::RpmPackage, :requires_root, :external => exclude_test do
  include Chef::Mixin::ShellOut

  let(:new_resource) do
    new_resource = Chef::Resource::RpmPackage.new(@pkg_name, run_context)
    new_resource.source @pkg_path
    new_resource
  end

  def rpm_pkg_should_be_installed(resource)
    # Due to dependency issues , different rpm pkgs are used in different platforms.
    # dummy rpm package works in aix, without any dependency issues.
    if ohai[:platform] == "aix"
      expect(shell_out("rpm -qa | grep dummy").exitstatus).to eq(0)
    # mytest rpm package works in centos, redhat and in suse without any dependency issues.
    else
      expect(shell_out("rpm -qa | grep mytest").exitstatus).to eq(0)
      ::File.exists?("/opt/mytest/mytest.sh") # The mytest rpm package contains the mytest.sh file
    end
  end

  def rpm_pkg_should_not_be_installed(resource)
    if ohai[:platform] == "aix"
      expect(shell_out("rpm -qa | grep dummy").exitstatus).to eq(1)
    else
      expect(shell_out("rpm -qa | grep mytest").exitstatus).to eq(1)
      !::File.exists?("/opt/mytest/mytest.sh")
    end
  end

  before(:all) do
    # Due to dependency issues , different rpm pkgs are used in different platforms.
    if ohai[:platform] == "aix"
      @pkg_name = "dummy"
      @pkg_version = "1-0"
      @pkg_path = "#{Dir.tmpdir}/dummy-1-0.aix6.1.noarch.rpm"
      FileUtils.cp(File.join(CHEF_SPEC_ASSETS, "dummy-1-0.aix6.1.noarch.rpm") , @pkg_path)
    else
      @pkg_name = "mytest"
      @pkg_version = "1.0-1"
      @pkg_path = "#{Dir.tmpdir}/mytest-1.0-1.noarch.rpm"
      FileUtils.cp(File.join(CHEF_SPEC_ASSETS, "mytest-1.0-1.noarch.rpm") , @pkg_path)
    end
  end

  after(:all) do
    FileUtils.rm @pkg_path
  end

  context "package install action" do
    it "should create a package" do
      new_resource.run_action(:install)
      rpm_pkg_should_be_installed(new_resource)
    end

    after(:each) do
      shell_out("rpm -qa | grep #{@pkg_name}-#{@pkg_version} | xargs rpm -e")
    end
  end

  context "package remove action" do
    before(:each) do
      shell_out("rpm -i #{@pkg_path}")
    end

    it "should remove an existing package" do
      new_resource.run_action(:remove)
      rpm_pkg_should_not_be_installed(new_resource)
    end
  end

  context "package upgrade action" do
    before(:each) do
      shell_out("rpm -i #{@pkg_path}")
      if ohai[:platform] == "aix"
        @pkg_version = "2-0"
        @pkg_path = "#{Dir.tmpdir}/dummy-2-0.aix6.1.noarch.rpm"
        FileUtils.cp(File.join(CHEF_SPEC_ASSETS, "dummy-2-0.aix6.1.noarch.rpm") , @pkg_path)
      else
        @pkg_version = "2.0-1"
        @pkg_path = "#{Dir.tmpdir}/mytest-2.0-1.noarch.rpm"
        FileUtils.cp(File.join(CHEF_SPEC_ASSETS, "mytest-2.0-1.noarch.rpm") , @pkg_path)
      end
    end

    it "should upgrade a package" do
      new_resource.run_action(:install)
      rpm_pkg_should_be_installed(new_resource)
    end

    after(:each) do
      shell_out("rpm -qa | grep #{@pkg_name}-#{@pkg_version} | xargs rpm -e")
      FileUtils.rm @pkg_path
    end
  end
end
