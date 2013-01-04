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

require 'spec_helper'
require 'ostruct'

describe Chef::Provider::CookbookFile do
  before do
    Chef::FileAccessControl.any_instance.stub(:set_all)
    Chef::FileAccessControl.any_instance.stub(:modified?).and_return(true)
    @cookbook_repo = File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks"))
    Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::FileSystemFileVendor.new(manifest, @cookbook_repo) }

    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    cl = Chef::CookbookLoader.new(@cookbook_repo)
    cl.load_cookbooks
    @cookbook_collection = Chef::CookbookCollection.new(cl)
    @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)

    @new_resource = Chef::Resource::CookbookFile.new('apache2_module_conf_generate.pl', @run_context)
    @new_resource.cookbook_name = 'apache2'
    @provider = Chef::Provider::CookbookFile.new(@new_resource, @run_context)

    @file_content=<<-EXPECTED
# apache2_module_conf_generate.pl
# this is just here for show.
EXPECTED

  end

  it "prefers the explicit cookbook name on the resource to the implicit one" do
    @new_resource.cookbook('nginx')
    @provider.resource_cookbook.should == 'nginx'
  end

  it "falls back to the implicit cookbook name on the resource" do
    @provider.resource_cookbook.should == 'apache2'
  end

  describe "when loading the current file state" do

    it "converts windows-y filenames to unix-y ones" do
      @new_resource.path('windows\stuff')
      @provider.load_current_resource
      @new_resource.path.should == 'windows/stuff'
    end

    it "sets the current resources path to the same as the new resource" do
      @new_resource.path('/tmp/file')
      @provider.load_current_resource
      @provider.current_resource.path.should == '/tmp/file'
    end
  end

  describe "when the enclosing directory of the target file location doesn't exist" do
    before do
      @new_resource.path("/tmp/no/such/intermediate/path/file.txt")
    end

    it "raises a specific error alerting the user to the problem" do
      lambda {@provider.run_action(:create)}.should raise_error(Chef::Exceptions::EnclosingDirectoryDoesNotExist)
    end
  end
  describe "when the file doesn't yet exist" do
    before do
      @install_to = Dir.tmpdir + '/apache2_modconf.pl'

      @current_resource = @new_resource.dup
      @provider.current_resource = @current_resource
    end

    after { ::File.exist?(File.dirname(@install_to)) && FileUtils.rm_rf(@install_to) }

    it "loads the current file state" do
      @provider.load_current_resource
      @provider.current_resource.checksum.should be_nil
    end

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

    it "installs the file for create_if_missing --> from Provider::File" do
      @new_resource.path(@install_to)
      @provider.should_receive(:backup_new_resource)
      @provider.stub!(:update_new_file_state)
      @provider.run_action(:create_if_missing)
      actual = IO.read(@install_to)
      actual.should == @file_content
    end

    it "marks the resource as updated by the last action --> being tested in the converge framework" do
      @new_resource.path(@install_to)
      @provider.stub!(:backup_new_resource)
      @provider.stub!(:set_file_access_controls)
      @provider.stub!(:update_new_file_state)
      @provider.run_action(:create)
      @new_resource.should be_updated
      @new_resource.should be_updated_by_last_action
    end

  end

  describe "when the file exists but has incorrect content" do
    before do
      @tempfile = Tempfile.open('cookbook_file_spec')
      @new_resource.path(@target_file = @tempfile.path)
      @tempfile.puts "the wrong content"
      @tempfile.close
      @current_resource = @new_resource.dup
      @provider.current_resource = @current_resource
    end

    it "stages the cookbook to a temporary file" do
      # prevents file backups where we might not have write access
      @provider.should_receive(:backup_new_resource) 
      @new_resource.path(@install_to)
      @provider.should_receive(:deploy_tempfile)
      @provider.run_action(:create)
    end

    it "overwrites it when the create action is called" do
      @provider.should_receive(:backup_new_resource)
      @provider.run_action(:create)
      actual = IO.read(@target_file)
      actual.should == @file_content
    end

    it "marks the resource as updated by the last action" do
      @provider.should_receive(:backup_new_resource)
      @provider.run_action(:create)
      @new_resource.should be_updated
      @new_resource.should be_updated_by_last_action
    end

    it "doesn't overwrite when the create if missing action is called" do
      @provider.should_not_receive(:set_file_access_controls)
      @provider.run_action(:create_if_missing)
      actual = IO.read(@target_file)
      actual.should == "the wrong content\n"
    end

    it "doesn't mark the resource as updated by the action for create_if_missing" do
      @provider.run_action(:create_if_missing)
      @new_resource.should_not be_updated
      @new_resource.should_not be_updated_by_last_action
    end

    after { @tempfile && @tempfile.close! }
  end

  describe "when the file has the correct content" do
    before do
      Chef::FileAccessControl.any_instance.stub(:modified?).and_return(false)
      @tempfile = Tempfile.open('cookbook_file_spec')
      # CHEF-2991: We handle CRLF very poorly and we don't know what line endings
      # our source file is going to have, so we use binary mode to preserve CRLF if needed.
      source_file = CHEF_SPEC_DATA + "/cookbooks/apache2/files/default/apache2_module_conf_generate.pl"
      @tempfile.binmode unless File.open(source_file, "rb") { |f| f.read =~ /\r/ }
      @new_resource.path(@target_file = @tempfile.path)
      @tempfile.write(@file_content)
      @tempfile.close
      @current_resource = @new_resource.dup
      @provider.current_resource = @current_resource
    end

    after { @tempfile && @tempfile.unlink}

    it "checks access control but does not alter content when action is create" do
      @provider.should_receive(:set_all_access_controls)
      @provider.should_not_receive(:stage_file_to_tmpdir)
      @provider.run_action(:create)
    end

    it "does not mark the resource as updated by the last action" do
      @provider.run_action(:create)
      @new_resource.should_not be_updated
      @new_resource.should_not be_updated_by_last_action
    end

    it "does not alter content or access control when action is create if missing" do
      @provider.should_not_receive(:set_all_access_controls)
      @provider.should_not_receive(:stage_file_to_tmpdir)
      @provider.run_action(:create_if_missing)
    end

  end
end
