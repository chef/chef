#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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
require "support/shared/unit/resource/static_provider_resolution"

describe Chef::Resource::Git do

  static_provider_resolution(
    resource: Chef::Resource::Git,
    provider: Chef::Provider::Git,
    name: :git,
    action: :sync
  )

  let(:resource) { Chef::Resource::Git.new("my awesome webapp") }

  it "is a kind of Scm Resource" do
    expect(resource).to be_a_kind_of(Chef::Resource::Scm)
    expect(resource).to be_an_instance_of(Chef::Resource::Git)
  end

  it "uses aliases revision as branch" do
    resource.branch "HEAD"
    expect(resource.revision).to eql("HEAD")
  end

  it "aliases revision as reference" do
    resource.reference "v1.0 tag"
    expect(resource.revision).to eql("v1.0 tag")
  end

end
