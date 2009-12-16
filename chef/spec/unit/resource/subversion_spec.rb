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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Resource::Subversion do
  
  before do
    @svn = Chef::Resource::Subversion.new("ohai, svn project!")
  end
  
  it "is a subclass of Resource::Scm" do
    @svn.should be_an_instance_of(Chef::Resource::Subversion)
    @svn.should be_a_kind_of(Chef::Resource::Scm)
  end
  
  it "uses the subversion provider" do
    @svn.provider.should eql(Chef::Provider::Subversion)
  end
  
  it "allows the force_export action" do
    @svn.allowed_actions.should include(:force_export)
  end
  
end