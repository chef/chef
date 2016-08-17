#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2009-2016, Chef Software Inc.
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
require "ostruct"

require "support/shared/unit/provider/file"

describe Chef::Provider::CookbookFile do
  let(:node) { double("Chef::Node") }
  let(:events) { double("Chef::Events").as_null_object } # mock all the methods
  let(:run_context) { double("Chef::RunContext", :node => node, :events => events) }
  let(:enclosing_directory) do
    canonicalize_path(File.expand_path(File.join(CHEF_SPEC_DATA, "templates")))
  end
  let(:resource_path) do
    canonicalize_path(File.expand_path(File.join(enclosing_directory, "seattle.txt")))
  end

  # Subject

  let(:provider) do
    provider = described_class.new(resource, run_context)
    allow(provider).to receive(:content).and_return(content)
    provider
  end

  let(:resource) do
    resource = Chef::Resource::CookbookFile.new("seattle", @run_context)
    resource.path(resource_path)
    resource.cookbook_name = "apache2"
    resource
  end

  let(:content) do
    content = double("Chef::Provider::CookbookFile::Content")
  end

  it_behaves_like Chef::Provider::File

  it_behaves_like "a file provider with source field"
end
