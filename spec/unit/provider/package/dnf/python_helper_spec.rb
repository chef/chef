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
