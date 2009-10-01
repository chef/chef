#
# Author:: Joe Williams (<joe@joetify.com>)
# Copyright:: Copyright (c) 2009 Joe Williams
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Provider::Script, "action_run" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::ErlCall",
      :null_object => true,
      :code => "io:format(\"burritos~n\", []).",
      :interpreter => 'erl_call',
      :user => nil,
      :group => nil,
      :cookie => nil,
      :distributed => false,
      :name_type => "sname",
      :node_name => "chef@localhost"
    )
    @provider = Chef::Provider::ErlCall.new(@node, @new_resource)
  end



end
