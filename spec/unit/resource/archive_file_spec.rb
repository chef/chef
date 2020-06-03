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

describe Chef::Resource::ArchiveFile do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::ArchiveFile.new("foo", run_context) }
  let(:provider) { resource.provider_for_action(:extract) }

  it "has a resource name of :archive_file" do
    expect(resource.resource_name).to eql(:archive_file)
  end

  it "has a name property of path" do
    expect(resource.path).to match(/.*foo$/)
  end

  it "sets the default action as :extract" do
    expect(resource.action).to eql([:extract])
  end

  it "supports :extract action" do
    expect { resource.action :extract }.not_to raise_error
  end

  it "mode property defaults to '755'" do
    expect(resource.mode).to eql("755")
  end

  it "mode property throws a deprecation warning if Integers are passed" do
    expect(Chef::Log).to receive(:deprecation)
    resource.mode 755
    provider.define_resource_requirements
  end

  it "options property defaults to [:time]" do
    expect(resource.options).to eql([:time])
  end
end
