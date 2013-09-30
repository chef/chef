#
# Author:: Serdar Sutay (<serdar@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

# Shared context used by both Powershell and Batch script provider
# tests.

shared_context Chef::Resource::WindowsScript do
  before(:all) do

    ohai_reader = Ohai::System.new
    ohai_reader.require_plugin("os")
    ohai_reader.require_plugin("windows::platform")

    new_node = Chef::Node.new
    new_node.consume_external_attrs(ohai_reader.data,{})

    events = Chef::EventDispatch::Dispatcher.new

    @run_context = Chef::RunContext.new(new_node, {}, events)
  end

  let(:script_output_path) do
    File.join(Dir.tmpdir, make_tmpname("windows_script_test"))
  end

  before(:each) do
k    File.delete(script_output_path) if File.exists?(script_output_path)
  end

  after(:each) do
    File.delete(script_output_path) if File.exists?(script_output_path)
  end
end
