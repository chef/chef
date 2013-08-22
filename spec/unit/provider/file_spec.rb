#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2008-2013 Opscode, Inc.
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

require 'support/shared/unit/provider/file'

describe Chef::Provider::File do

  let(:resource) do
    # need to check for/against mutating state within the new_resource, so don't mock
    resource = Chef::Resource::File.new("seattle")
    resource.path(resource_path)
    resource
  end

  let(:content) do
    content = mock('Chef::Provider::File::Content')
  end

  let(:node) { double('Chef::Node') }
  let(:events) { double('Chef::Events').as_null_object }  # mock all the methods
  let(:run_context) { double('Chef::RunContext', :node => node, :events => events) }
  let(:enclosing_directory) {
    canonicalize_path(File.expand_path(File.join(CHEF_SPEC_DATA, "templates")))
  }
  let(:resource_path) {
    canonicalize_path(File.expand_path(File.join(enclosing_directory, "seattle.txt")))
  }

  # Subject

  let(:provider) do
    provider = described_class.new(resource, run_context)
    provider.stub!(:content).and_return(content)
    provider
  end

  it_behaves_like Chef::Provider::File
end

