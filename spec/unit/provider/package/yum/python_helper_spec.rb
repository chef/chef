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

# NOTE: most of the tests of this functionality are baked into the func tests for the yum package provider

describe Chef::Provider::Package::Yum::PythonHelper do
  let(:helper) { Chef::Provider::Package::Yum::PythonHelper.instance }
  before(:each) { Singleton.__init__(Chef::Provider::Package::Yum::PythonHelper) }

  it "propagates stacktraces on stderr from the forked subprocess", :rhel do
    allow(helper).to receive(:yum_command).and_return("ruby -e 'raise \"your hands in the air\"'")
    expect { helper.package_query(:whatprovides, "tcpdump") }.to raise_error(/your hands in the air/)
  end
end
