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
  let(:expected_content) do
    content = File.open(File.join(CHEF_SPEC_DATA, 'remote_file', 'nyan_cat.png'), "rb") do |f|
      f.read
    end
    content.force_encoding(Encoding::BINARY) if content.respond_to?(:force_encoding)
    content
  end

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

  let(:default_mode) do
    # TODO: Lots of ugly here :(
    # RemoteFile uses FileUtils.cp. FileUtils does a copy by opening the
    # destination file and writing to it. Before 1.9.3, it does not preserve
    # the mode of the copied file. In 1.9.3 and after, it does. So we have to
    # figure out what the default mode ought to be via heuristic.

    t = Tempfile.new("get-the-mode")
    path = t.path
    path_2 = t.path + "fileutils-mode-test"
    FileUtils.cp(path, path_2)
    t.close
    m = File.stat(path_2).mode
    (07777 & m).to_s(8)
  end

  before(:all) do
    @server = TinyServer::Manager.new
    @server.start
    @api = TinyServer::API.instance
    @api.clear
    @api.get("/nyan_cat.png", 200) {
      File.open(File.join(CHEF_SPEC_DATA, 'remote_file', 'nyan_cat.png'), "rb") do |f|
        f.read
      end
    }
  end

  after(:all) do
    @server.stop
  end

  it_behaves_like "a file resource"

  it_behaves_like "a securable resource with reporting"
end
