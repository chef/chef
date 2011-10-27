#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

describe Chef::Resource::CookbookFile do
  before do
    @cookbook_file = Chef::Resource::CookbookFile.new('sourcecode_tarball.tgz')
  end

  it "uses the name parameter for the source parameter" do
    @cookbook_file.name.should == 'sourcecode_tarball.tgz'
  end

  it "has a source parameter" do
    @cookbook_file.name('config_file.conf')
    @cookbook_file.name.should == 'config_file.conf'
  end

  it "defaults to a nil cookbook parameter (current cookbook will be used)" do
    @cookbook_file.cookbook.should be_nil
  end

  it "has a cookbook parameter" do
    @cookbook_file.cookbook("munin")
    @cookbook_file.cookbook.should == 'munin'
  end

  it "sets the provider to Chef::Provider::CookbookFile" do
    @cookbook_file.provider.should == Chef::Provider::CookbookFile
  end

end
