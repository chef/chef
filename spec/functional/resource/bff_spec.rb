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

require "functional/resource/base"
require "chef/mixin/shell_out"

# Run the test only for AIX platform.
describe Chef::Resource::BffPackage, :requires_root, :external => ohai[:platform] != "aix" do
  include Chef::Mixin::ShellOut

  let(:new_resource) do
    new_resource = Chef::Resource::BffPackage.new(@pkg_name, run_context)
    new_resource.source @pkg_path
    new_resource
  end

  def bff_pkg_should_be_installed(resource)
    expect(shell_out("lslpp -L #{resource.name}").exitstatus).to eq(0)
    ::File.exists?("/usr/PkgA/bin/acommand")
  end

  def bff_pkg_should_be_removed(resource)
    expect(shell_out("lslpp -L #{resource.name}").exitstatus).to eq(1)
    !::File.exists?("/usr/PkgA/bin/acommand")
  end

  before(:all) do
    @pkg_name = "PkgA.rte"
    @pkg_path = "#{Dir.tmpdir}/PkgA.1.0.0.0.bff"
    FileUtils.cp "spec/functional/assets/PkgA.1.0.0.0.bff" , @pkg_path
  end

  after(:all) do
    FileUtils.rm @pkg_path
  end

  context "package install action" do
    it "should install a package" do
      new_resource.run_action(:install)
      bff_pkg_should_be_installed(new_resource)
    end

    after(:each) do
      shell_out("installp -u #{@pkg_name}")
    end
  end

  context "package install action with options" do
    it "should install a package" do
      new_resource.options("-e/tmp/installp.log")
      new_resource.run_action(:install)
      bff_pkg_should_be_installed(new_resource)
    end

    after(:each) do
      shell_out("installp -u #{@pkg_name}")
      FileUtils.rm "#{Dir.tmpdir}/installp.log"
    end
  end

  context "package upgrade action" do
    before(:each) do
      shell_out("installp -aYF -d #{@pkg_path} #{@pkg_name}")
      @pkg_path = "#{Dir.tmpdir}/PkgA.2.0.0.0.bff"
      FileUtils.cp "spec/functional/assets/PkgA.2.0.0.0.bff" , @pkg_path
    end

    it "should upgrade package" do
      new_resource.run_action(:install)
      bff_pkg_should_be_installed(new_resource)
    end

    after(:each) do
      shell_out("installp -u #{@pkg_name}")
      FileUtils.rm @pkg_path
    end
  end

  context "package remove action" do
    before(:each) do
      shell_out("installp -aYF -d #{@pkg_path} #{@pkg_name}")
    end

    it "should remove an installed package" do
      new_resource.run_action(:remove)
      bff_pkg_should_be_removed(new_resource)
    end
  end

  context "package remove action with options" do
    before(:each) do
      shell_out("installp -aYF -d #{@pkg_path} #{@pkg_name}")
    end

    it "should remove an installed package" do
      new_resource.options("-e/tmp/installp.log")
      new_resource.run_action(:remove)
      bff_pkg_should_be_removed(new_resource)
    end

    after(:each) do
      FileUtils.rm "#{Dir.tmpdir}/installp.log"
    end
  end
end
