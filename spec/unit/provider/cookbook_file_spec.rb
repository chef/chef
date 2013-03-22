#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2009-2013 Opscode, Inc.
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
require 'ostruct'

require 'support/shared/unit/provider/file'

describe Chef::Provider::CookbookFile do

  let(:resource) do
    resource = Chef::Resource::CookbookFile.new("seattle", @run_context)
    resource.path(resource_path)
    resource.cookbook_name = 'apache2'
    resource
  end

  let(:content) do
    content = mock('Chef::Provider::File::Content::CookbookFile')
  end

  it_behaves_like Chef::Provider::File

#  before do
#    Chef::FileAccessControl.any_instance.stub(:set_all)
#    Chef::FileAccessControl.any_instance.stub(:modified?).and_return(true)
#    @cookbook_repo = File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks"))
#    Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::FileSystemFileVendor.new(manifest, @cookbook_repo) }
#
#    @node = Chef::Node.new
#    @events = Chef::EventDispatch::Dispatcher.new
#    cl = Chef::CookbookLoader.new(@cookbook_repo)
#    cl.load_cookbooks
#    @cookbook_collection = Chef::CookbookCollection.new(cl)
#    @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)
#
#    @new_resource = Chef::Resource::CookbookFile.new('apache2_module_conf_generate.pl', @run_context)
#    @new_resource.cookbook_name = 'apache2'
#    @provider = Chef::Provider::CookbookFile.new(@new_resource, @run_context)
#
#    @file_content=<<-EXPECTED
## apache2_module_conf_generate.pl
## this is just here for show.
#EXPECTED
#
#  end

# FIXME: move to Chef::Provider::File
#  describe "when loading the current file state" do
#
#    it "converts windows-y filenames to unix-y ones" do
#      @new_resource.path('windows\stuff')
#      @provider.load_current_resource
#      @new_resource.path.should == 'windows/stuff'
#    end
#
#    it "sets the current resources path to the same as the new resource" do
#      @new_resource.path('/tmp/file')
#      @provider.load_current_resource
#      @provider.current_resource.path.should == '/tmp/file'
#    end
#  end

  describe "when the file doesn't yet exist" do
    before do
      @install_to = Dir.tmpdir + '/apache2_modconf.pl'

      @current_resource = @new_resource.dup
      @provider.current_resource = @current_resource
    end

    after { ::File.exist?(File.dirname(@install_to)) && FileUtils.rm_rf(@install_to) }

    it "looks up a file from the cookbook cache" do
      expected = CHEF_SPEC_DATA + "/cookbooks/apache2/files/default/apache2_module_conf_generate.pl"
      @provider.file_cache_location.should == expected
    end

    it "installs the file from the cookbook cache" do
      @new_resource.path(@install_to)
      @provider.should_receive(:backup_new_resource)
      @provider.stub!(:update_new_file_state)
      @provider.run_action(:create)
      actual = IO.read(@install_to)
      actual.should == @file_content
    end
  end

end
