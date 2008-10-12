#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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

describe Chef::Provider::Package, "initialize" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource", :null_object => true)
  end
  
  it "should return a Chef::Provider::Service object" do
    provider = Chef::Provider::Service.new(@node, @new_resource)
    provider.should be_a_kind_of(Chef::Provider::Service)
  end  
end

describe Chef::Provider::Service, "action_enable" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef"
    )
    @current_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef"
    )
    @provider = Chef::Provider::Service.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:enable_service).and_return(true)
  end

end

describe Chef::Provider::Service, "action_disable" do

end

describe Chef::Provider::Service, "action_start" do

end

describe Chef::Provider::Service, "action_stop" do

end
