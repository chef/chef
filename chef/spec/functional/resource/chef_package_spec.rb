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

describe Chef::Resource::ChefPackage do

  def create_resource
    events = Chef::EventDispatch::Dispatcher.new
    node = Chef::Node.new
    run_context = Chef::RunContext.new(node, {}, events)
    resource = Chef::Resource::ChefPackage.new('tmux', run_context)
    resource
  end

  let!(:resource) do
    create_resource
  end

  context "after creating a ChefPackage resource" do
    it "it should create a matching Package resource" do
      resource.run_context.resource_collection.lookup('package[tmux]').should_not be_nil
    end
  end
end
