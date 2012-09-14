#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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
require 'tiny_server'

describe Chef::Resource::RemoteFile do
  include_context Chef::Resource::File

  let(:file_base) { "remote_file_spec" }
  let(:source) { 'http://localhost:9000/nyan_cat.png' }
  let(:expected_content) { IO.read(File.join(CHEF_SPEC_DATA, 'remote_file', 'nyan_cat.png')) }

  def create_resource
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    resource = Chef::Resource::RemoteFile.new(path, run_context)
    resource.source(source)
    resource
  end

  let!(:resource) do
    create_resource
  end

  before(:all) do
    Thin::Logging.silent = false
    @server = TinyServer::Manager.new
    @server.start
    @api = TinyServer::API.instance
    @api.clear
    @api.get("/nyan_cat.png", 200) {
      IO.read(File.join(CHEF_SPEC_DATA, 'remote_file', 'nyan_cat.png'))
    }
  end

  after(:all) do
    @server.stop
  end

  it_behaves_like "a file resource"
end
