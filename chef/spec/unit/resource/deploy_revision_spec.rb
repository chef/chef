#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2009 Daniel DeLeo
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

describe Chef::Resource::DeployRevision do
  
  it "defaults to the revision deploy provider" do
    @resource = Chef::Resource::DeployRevision.new("deploy _this_!")
    @resource.provider.should == Chef::Provider::Deploy::Revision
  end

  it "has a name of deploy_revision" do
    @resource = Chef::Resource::DeployRevision.new("deploy _this_!")
    @resource.resource_name.should == :deploy_revision
  end
  
end

describe Chef::Resource::DeployBranch do
  
  it "defaults to the revision deploy provider" do
    @resource = Chef::Resource::DeployBranch.new("deploy _this_!")
    @resource.provider.should == Chef::Provider::Deploy::Revision
  end

  it "has a name of deploy_branch" do
    @resource = Chef::Resource::DeployBranch.new("deploy _this_!")
    @resource.resource_name.should == :deploy_branch
  end
  
end
