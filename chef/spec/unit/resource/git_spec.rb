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

describe Chef::Resource::Git do
  
  before(:each) do
    @git = Chef::Resource::Git.new("my awesome webapp")
  end
  
  it "is a kind of Scm Resource" do
    @git.should be_a_kind_of(Chef::Resource::Scm)
    @git.should be_an_instance_of(Chef::Resource::Git)
  end
  
  it "uses the git provider" do
    @git.provider.should eql(Chef::Provider::Git)
  end
  
  it "uses aliases revision as branch" do
    @git.branch "HEAD"
    @git.revision.should eql("HEAD")
  end
  
  it "aliases revision as reference" do
    @git.reference "v1.0 tag"
    @git.revision.should eql("v1.0 tag")
  end
  
end
