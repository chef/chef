#
# Author:: Matthew Kent (<mkent@magoazul.com>)
# Author:: Steven Danna (<steve@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'chef/cookbook_uploader'
require 'timeout'

describe Chef::Knife::CookbookUpload do
  let(:cookbook) { Chef::CookbookVersion.new('test_cookbook', '/tmp/blah.txt') }

  let(:cookbooks_by_name) do
    {cookbook.name => cookbook}
  end

  let(:cookbook_loader) do
    cookbook_loader = cookbooks_by_name.dup
    cookbook_loader.stub(:merged_cookbooks).and_return([])
    cookbook_loader.stub(:load_cookbooks).and_return(cookbook_loader)
    cookbook_loader
  end

  let(:cookbook_uploader) { double(:upload_cookbooks => nil) }

  let(:output) { StringIO.new }

  let(:name_args) { ['test_cookbook'] }

  let(:knife) do
    k = Chef::Knife::CookbookUpload.new
    k.name_args = name_args
    k.ui.stub(:stdout).and_return(output)
    k.ui.stub(:stderr).and_return(output)
    k
  end

  before(:each) do
    Chef::CookbookLoader.stub(:new).and_return(cookbook_loader)
  end

  describe 'with --concurrency' do
    it 'should upload cookbooks with predefined concurrency' do
      Chef::CookbookVersion.stub(:list_all_versions).and_return({})
      knife.config[:concurrency] = 3
      test_cookbook = Chef::CookbookVersion.new('test_cookbook', '/tmp/blah')
      cookbook_loader.stub(:each).and_yield("test_cookbook", test_cookbook)
      cookbook_loader.stub(:cookbook_names).and_return(["test_cookbook"])
      Chef::CookbookUploader.should_receive(:new).
        with( kind_of(Array), { :force => nil, :concurrency => 3}).
        and_return(double("Chef::CookbookUploader", :upload_cookbooks=> true))
      knife.run
    end
  end

  describe 'run' do
    before(:each) do
      Chef::CookbookUploader.stub(:new => cookbook_uploader)
      Chef::CookbookVersion.stub(:list_all_versions).and_return({})
    end

    it 'should print usage and exit when a cookbook name is not provided' do
      knife.name_args = []
      knife.should_receive(:show_usage)
      knife.ui.should_receive(:fatal)
      lambda { knife.run }.should raise_error(SystemExit)
    end

    describe 'when specifying a cookbook name' do
      it 'should upload the cookbook' do
        knife.should_receive(:upload).once
        knife.run
      end

      it 'should report on success' do
        knife.should_receive(:upload).once
        knife.ui.should_receive(:info).with(/Uploaded 1 cookbook/)
        knife.run
      end
    end

    describe 'when specifying the same cookbook name twice' do
      it 'should upload the cookbook only once' do
        knife.name_args = ['test_cookbook', 'test_cookbook']
        knife.should_receive(:upload).once
        knife.run
      end
    end

    context "when uploading a cookbook that uses deprecated overlays" do

      before do
        cookbook_loader.stub(:merged_cookbooks).and_return(['test_cookbook'])
        cookbook_loader.stub(:merged_cookbook_paths).
          and_return({'test_cookbook' => %w{/path/one/test_cookbook /path/two/test_cookbook}})
      end

      it "emits a warning" do
        knife.run
        expected_message=<<-E
WARNING: The cookbooks: test_cookbook exist in multiple places in your cookbook_path.
A composite version of these cookbooks has been compiled for uploading.

IMPORTANT: In a future version of Chef, this behavior will be removed and you will no longer
be able to have the same version of a cookbook in multiple places in your cookbook_path.
WARNING: The affected cookbooks are located:
test_cookbook:
  /path/one/test_cookbook
  /path/two/test_cookbook
E
        output.string.should include(expected_message)
      end
    end

    describe 'when specifying a cookbook name among many' do
      let(:name_args) { ['test_cookbook1'] }

      let(:cookbooks_by_name) do
        {
          'test_cookbook1' => Chef::CookbookVersion.new('test_cookbook1', '/tmp/blah'),
          'test_cookbook2' => Chef::CookbookVersion.new('test_cookbook2', '/tmp/blah'),
          'test_cookbook3' => Chef::CookbookVersion.new('test_cookbook3', '/tmp/blah')
        }
      end

      it "should read only one cookbook" do
        cookbook_loader.should_receive(:[]).once.with('test_cookbook1').and_call_original
        knife.run
      end

      it "should not read all cookbooks" do
        cookbook_loader.should_not_receive(:load_cookbooks)
        knife.run
      end

      it "should upload only one cookbook" do
        knife.should_receive(:upload).exactly(1).times
        knife.run
      end
    end

    # This is testing too much.  We should break it up.
    describe 'when specifying a cookbook name with dependencies' do
      let(:name_args) { ["test_cookbook2"] }

      let(:cookbooks_by_name) do
        { "test_cookbook1" => test_cookbook1,
          "test_cookbook2" => test_cookbook2,
          "test_cookbook3" => test_cookbook3 }
      end

      let(:test_cookbook1) { Chef::CookbookVersion.new('test_cookbook1', '/tmp/blah') }

      let(:test_cookbook2) do
        c = Chef::CookbookVersion.new('test_cookbook2')
        c.metadata.depends("test_cookbook3")
        c
      end

      let(:test_cookbook3) do
        c = Chef::CookbookVersion.new('test_cookbook3')
        c.metadata.depends("test_cookbook1")
        c.metadata.depends("test_cookbook2")
        c
      end

      it "should upload all dependencies once" do
        knife.config[:depends] = true
        knife.stub(:cookbook_names).and_return(["test_cookbook1", "test_cookbook2", "test_cookbook3"])
        knife.should_receive(:upload).exactly(3).times
        lambda do
          Timeout::timeout(5) do
            knife.run
          end
        end.should_not raise_error
      end
    end

    describe 'when specifying a cookbook name with missing dependencies' do
      let(:cookbook_dependency) { Chef::CookbookVersion.new('dependency', '/tmp/blah') }

      before(:each) do
        cookbook.metadata.depends("dependency")
        cookbook_loader.stub(:[])  do |ckbk|
          { "test_cookbook" =>  cookbook,
            "dependency" => cookbook_dependency}[ckbk]
        end
        knife.stub(:cookbook_names).and_return(["cookbook_dependency", "test_cookbook"])
        @stdout, @stderr, @stdin = StringIO.new, StringIO.new, StringIO.new
        knife.ui = Chef::Knife::UI.new(@stdout, @stderr, @stdin, {})
      end

      it 'should exit and not upload the cookbook' do
        cookbook_loader.should_receive(:[]).once.with('test_cookbook')
        cookbook_loader.should_not_receive(:load_cookbooks)
        cookbook_uploader.should_not_receive(:upload_cookbooks)
        expect {knife.run}.to raise_error(SystemExit)
      end

      it 'should output a message for a single missing dependency' do
        expect {knife.run}.to raise_error(SystemExit)
        @stderr.string.should include('Cookbook test_cookbook depends on cookbooks which are not currently')
        @stderr.string.should include('being uploaded and cannot be found on the server.')
        @stderr.string.should include("The missing cookbook(s) are: 'dependency' version '>= 0.0.0'")
      end

      it 'should output a message for a multiple missing dependencies which are concatenated' do
        cookbook_dependency2 = Chef::CookbookVersion.new('dependency2')
        cookbook.metadata.depends("dependency2")
        cookbook_loader.stub(:[])  do |ckbk|
          { "test_cookbook" =>  cookbook,
            "dependency" => cookbook_dependency,
            "dependency2" => cookbook_dependency2}[ckbk]
        end
        knife.stub(:cookbook_names).and_return(["dependency", "dependency2", "test_cookbook"])
        expect {knife.run}.to raise_error(SystemExit)
        @stderr.string.should include('Cookbook test_cookbook depends on cookbooks which are not currently')
        @stderr.string.should include('being uploaded and cannot be found on the server.')
        @stderr.string.should include("The missing cookbook(s) are:")
        @stderr.string.should include("'dependency' version '>= 0.0.0'")
        @stderr.string.should include("'dependency2' version '>= 0.0.0'")
      end
    end

    it "should freeze the version of the cookbooks if --freeze is specified" do
      knife.config[:freeze] = true
      cookbook.should_receive(:freeze_version).once
      knife.run
    end

    describe 'with -a or --all' do
      before(:each) do
        knife.config[:all] = true
        @test_cookbook1 = Chef::CookbookVersion.new('test_cookbook1', '/tmp/blah')
        @test_cookbook2 = Chef::CookbookVersion.new('test_cookbook2', '/tmp/blah')
        cookbook_loader.stub(:each).and_yield("test_cookbook1", @test_cookbook1).and_yield("test_cookbook2", @test_cookbook2)
        cookbook_loader.stub(:cookbook_names).and_return(["test_cookbook1", "test_cookbook2"])
      end

      it 'should upload all cookbooks' do
        knife.should_receive(:upload).once
        knife.run
      end

      it 'should report on success' do
        knife.should_receive(:upload).once
        knife.ui.should_receive(:info).with(/Uploaded all cookbooks/)
        knife.run
      end

      it 'should update the version constraints for an environment' do
        knife.stub(:assert_environment_valid!).and_return(true)
        knife.config[:environment] = "production"
        knife.should_receive(:update_version_constraints).once
        knife.run
      end
    end

    describe 'when a frozen cookbook exists on the server' do
      it 'should fail to replace it' do
        exception = Chef::Exceptions::CookbookFrozen.new
        cookbook_uploader.should_receive(:upload_cookbooks).
          and_raise(exception)
        knife.ui.stub(:error)
        knife.ui.should_receive(:error).with(exception)
        lambda { knife.run }.should raise_error(SystemExit)
      end

      it 'should not update the version constraints for an environment' do
        knife.stub(:assert_environment_valid!).and_return(true)
        knife.config[:environment] = "production"
        knife.stub(:upload).and_raise(Chef::Exceptions::CookbookFrozen)
        knife.ui.should_receive(:error).with(/Failed to upload 1 cookbook/)
        knife.ui.should_receive(:warn).with(/Not updating version constraints/)
        knife.should_not_receive(:update_version_constraints)
        lambda { knife.run }.should raise_error(SystemExit)
      end
    end
  end # run
end
