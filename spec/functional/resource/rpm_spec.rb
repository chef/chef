#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'functional/resource/base'
require 'chef/mixin/shell_out'

# run this test only for following platforms.
exclude_test = !['aix', 'centos', 'redhat', 'suse'].include?(ohai[:platform])
describe Chef::Resource::RpmPackage, :requires_root ,:external => exclude_test do
  include Chef::Mixin::ShellOut

  let(:new_resource) do
     new_resource = Chef::Resource::RpmPackage.new(@pkg_name, run_context)
     new_resource.source @pkg_path
     new_resource
  end

  def rpm_pkg_should_be_installed(resource)
    case ohai[:platform]
    # Due to dependency issues , different rpm pkgs are used in different platforms.
    # glib rpm package works in aix, without any dependency issues.
    when "aix"
      expect(shell_out("rpm -qa | grep glib").exitstatus).to eq(0)
    # mytest rpm package works in centos, redhat and in suse without any dependency issues.
    when "centos", "redhat", "suse"
      expect(shell_out("rpm -qa | grep mytest").exitstatus).to eq(0)
    end
  end

  def rpm_pkg_should_not_be_installed(resource)
    case ohai[:platform]
    when "aix"
      expect(shell_out("rpm -qa | grep glib").exitstatus).to eq(0)
    when "centos", "redhat", "suse"
      expect(shell_out("rpm -qa | grep mytest").exitstatus).to eq(1)
    end
  end

  before(:all) do
    case ohai[:platform]
    # Due to dependency issues , different rpm pkgs are used in different platforms.
    when "aix"
      FileUtils.cp 'spec/functional/assets/glib-1.2.10-2.aix4.3.ppc.rpm' , "/tmp/glib-1.2.10-2.aix4.3.ppc.rpm"
      @pkg_name = "glib"
      @pkg_path = "/tmp/glib-1.2.10-2.aix4.3.ppc.rpm"
    when "centos", "redhat", "suse"
      FileUtils.cp 'spec/functional/assets/mytest-1.0-1.noarch.rpm' , "/tmp/mytest-1.0-1.noarch.rpm"
      @pkg_name = "mytest"
      @pkg_path = "/tmp/mytest-1.0-1.noarch.rpm"
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
     new_resource.run_action(:remove)
    end
  end

  context "package remove action" do
    before(:each) do
     new_resource.run_action(:install)
    end

    it "should remove an existing package" do
      new_resource.run_action(:remove)
      rpm_pkg_should_not_be_installed(new_resource)
    end
  end
end
