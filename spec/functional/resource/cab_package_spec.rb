#
# Author:: Vasundhara Jagdale (<vasundhara.jagdale@msystechnologies.com>)
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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
require "chef/mixin/powershell_out"

describe Chef::Resource::CabPackage, :windows_only do
  include Chef::Mixin::PowershellOut

  let(:package_source) { File.join(CHEF_SPEC_ASSETS, "dummy-cab-23448.cab") }

  let(:new_resource) do
    new_resource = Chef::Resource::CabPackage.new("test-package", run_context)
    new_resource.source = package_source
    new_resource
  end

  let(:installed_version) { proc { stdout = powershell_out!("dism.exe /Online /Get-PackageInfo /PackagePath:\"#{new_resource.source}\" /NoRestart").stdout } }

  context "installing package" do
    after { remove_package }

    it "installs the package" do
      new_resource.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end

    it "raises error if package is not found" do
      new_resource.source = File.join(CHEF_SPEC_ASSETS, "test.cab")
      expect { new_resource.run_action(:install) }.to raise_error Chef::Exceptions::Package
    end
  end
end

def remove_package
  pkg_to_remove = Chef::Resource::CabPackage.new("test-package", run_context)
  pkg_to_remove.source = package_source
  pkg_to_remove.run_action(:remove)
end
