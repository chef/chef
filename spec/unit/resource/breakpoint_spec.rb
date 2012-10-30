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

describe Chef::Resource::Breakpoint do
  
  before do
    @breakpoint = Chef::Resource::Breakpoint.new
  end
  
  it "allows the action :break" do
    @breakpoint.allowed_actions.should include(:break)
  end
  
  it "defaults to the break action" do
    @breakpoint.action.should == "break"
  end
  
  it "names itself after the line number of the file where it's created" do
    @breakpoint.name.should match(/breakpoint_spec\.rb\:[\d]{2}\:in \`new\'$/)
  end
  
  it "uses the breakpoint provider" do
    @breakpoint.provider.should == Chef::Provider::Breakpoint
  end
  
end
