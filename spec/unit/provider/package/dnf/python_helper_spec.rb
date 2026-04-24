#
# Copyright:: Copyright (c) Chef Software Inc.
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

# NOTE: most of the tests of this functionality are baked into the func tests for the dnf package provider

# run this test only for following platforms.
exclude_test = !(%w{rhel fedora amazon}.include?(ohai[:platform_family]) && File.exist?("/usr/bin/dnf"))
describe Chef::Provider::Package::Dnf::PythonHelper, :requires_root, external: exclude_test do
  let(:helper) { Chef::Provider::Package::Dnf::PythonHelper.instance }
  before(:each) { Singleton.__init__(Chef::Provider::Package::Dnf::PythonHelper) }

  it "propagates stacktraces on stderr from the forked subprocess", :rhel do
    allow(helper).to receive(:dnf_command).and_return("ruby -e 'raise \"your hands in the air\"'")
    expect { helper.package_query(:whatprovides, "tcpdump") }.to raise_error(/your hands in the air/)
  end

  it "compares EVRAs with dots in the release correctly" do
    expect(helper.compare_versions("0:1.8.29-6.el8.x86_64", "0:1.8.29-6.el8_3.1.x86_64")).to eql(-1)
  end
end

describe Chef::Provider::Package::Dnf::PythonHelper, "#dnf_command" do
  let(:helper) do
    Singleton.__init__(Chef::Provider::Package::Dnf::PythonHelper)
    Chef::Provider::Package::Dnf::PythonHelper.instance
  end

  let(:dnf_helper_path) do
    Chef::Provider::Package::Dnf::PythonHelper::DNF_HELPER
  end

  let(:success_result) { double("shell_out", exitstatus: 0) }
  let(:failure_result) { double("shell_out", exitstatus: 1) }

  it "stops shell_out calls after finding the first working python" do
    allow(helper).to receive(:where).and_return(
      ["/usr/bin/python3", "/usr/bin/python2", "/usr/bin/python2.7"]
    )

    expect(helper).to receive(:shell_out)
      .with("/usr/bin/python3 -c 'import dnf'")
      .and_return(success_result)
    expect(helper).not_to receive(:shell_out)
      .with("/usr/bin/python2 -c 'import dnf'")
    expect(helper).not_to receive(:shell_out)
      .with("/usr/bin/python2.7 -c 'import dnf'")

    expect(helper.dnf_command).to eq("/usr/bin/python3 #{dnf_helper_path}")
  end

  it "tries subsequent executables when earlier ones fail" do
    allow(helper).to receive(:where).and_return(
      ["/usr/bin/python3", "/usr/bin/python2", "/usr/bin/python2.7"]
    )

    expect(helper).to receive(:shell_out)
      .with("/usr/bin/python3 -c 'import dnf'")
      .and_return(failure_result)
    expect(helper).to receive(:shell_out)
      .with("/usr/bin/python2 -c 'import dnf'")
      .and_return(success_result)

    expect(helper.dnf_command).to eq("/usr/bin/python2 #{dnf_helper_path}")
  end

  it "raises when no executable can import dnf" do
    allow(helper).to receive(:where).and_return(
      ["/usr/bin/python3"]
    )

    expect(helper).to receive(:shell_out)
      .with("/usr/bin/python3 -c 'import dnf'")
      .and_return(failure_result)

    expect { helper.dnf_command }.to raise_error(
      Chef::Exceptions::Package,
      "cannot find dnf libraries, you may need to use yum_package"
    )
  end

  it "raises when no executables are found" do
    allow(helper).to receive(:where).and_return([])

    expect { helper.dnf_command }.to raise_error(
      Chef::Exceptions::Package,
      "cannot find dnf libraries, you may need to use yum_package"
    )
  end
end
