#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

describe Chef::Provider::Deploy::Timestamped do
  
  before do
    @release_time = Time.utc( 2004, 8, 15, 16, 23, 42)
    Time.stub!(:now).and_return(@release_time)
    @expected_release_dir = "/my/deploy/dir/releases/20040815162342"
    @resource = Chef::Resource::Deploy.new("/my/deploy/dir")
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @timestamped_deploy = Chef::Provider::Deploy::Timestamped.new(@resource, @run_context)
    @runner = mock("runnah")
    Chef::Runner.stub!(:new).and_return(@runner)
  end
  
  it "gives a timestamp for release_slug" do
    @timestamped_deploy.send(:release_slug).should == "20040815162342"
  end
  
end
