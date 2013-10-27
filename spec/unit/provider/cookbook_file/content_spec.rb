#
# Author:: Lamont Granquist (<lamont@opscode.com>)
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

require 'spec_helper'

describe Chef::Provider::CookbookFile::Content do

  let(:new_resource) { mock('Chef::Resource::CookbookFile (new)', :cookbook_name => 'apache2', :cookbook => 'apache2') }
  let(:content) do
    @run_context = mock('Chef::RunContext')
    @current_resource = mock('Chef::Resource::CookbookFile (current)')
    Chef::Provider::CookbookFile::Content.new(new_resource, @current_resource, @run_context)
  end

  it "prefers the explicit cookbook name on the resource to the implicit one" do
    new_resource.stub!(:cookbook).and_return('nginx')
    content.send(:resource_cookbook).should == 'nginx'
  end

  it "falls back to the implicit cookbook name on the resource" do
    content.send(:resource_cookbook).should == 'apache2'
  end

end

