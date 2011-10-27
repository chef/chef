#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'tiny_server'

describe Chef::Knife::Exec do
  before(:all) do
    Thin::Logging.silent = false

    @server = TinyServer::Manager.new#(:debug => true)
    @server.start
  end

  before(:each) do
    @knife = Chef::Knife::Exec.new
    @api = TinyServer::API.instance
    @api.clear

    Chef::Config[:node_name] = false
    Chef::Config[:client_key] = false
    Chef::Config[:chef_server_url] = 'http://localhost:9000'

    $output = StringIO.new
  end

  after(:all) do
    @server.stop
  end

  it "executes a script in the context of the shef main context" do
    @node = Chef::Node.new
    @node.name("ohai-world")
    response = {"rows" => [@node],"start" => 0,"total" => 1}
    @api.get(%r{^/search/node}, 200, response.to_json)
    code = "$output.puts nodes.all.inspect"
    @knife.config[:exec] = code
    @knife.run
    $output.string.should match(%r{node\[ohai-world\]})
  end

end
