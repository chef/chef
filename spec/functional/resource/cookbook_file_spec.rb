#
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'spec_helper'

describe Chef::Resource::CookbookFile do
  include_context Chef::Resource::File

  let(:file_base) { 'cookbook_file_spec' }
  let(:source) { 'java.response' }
  let(:cookbook_name) { 'java' }
  let(:expected_content) do
    content = File.open(File.join(CHEF_SPEC_DATA, 'cookbooks', 'java', 'files', 'default', 'java.response'), "rb") do |f|
      f.read
    end
    content.force_encoding(Encoding::BINARY) if content.respond_to?(:force_encoding)
    content
  end

  let(:default_mode) { "600" }

  it_behaves_like "a securable resource with reporting"

  def create_resource
    # set up cookbook collection for this run to use, based on our
    # spec data.
    cookbook_repo = File.expand_path(File.join(CHEF_SPEC_DATA, 'cookbooks'))
    Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::FileSystemFileVendor.new(manifest, cookbook_repo) }
    loader = Chef::CookbookLoader.new(cookbook_repo)
    loader.load_cookbooks
    cookbook_collection = Chef::CookbookCollection.new(loader)

    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, cookbook_collection, events)
    resource = Chef::Resource::CookbookFile.new(path, run_context)
    resource.cookbook(cookbook_name)
    resource.source(source)

    resource
  end

  let!(:resource) do
    create_resource
  end

  it_behaves_like "a file resource"
end
