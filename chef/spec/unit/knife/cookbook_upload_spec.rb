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
  before(:each) do
    @knife = Chef::Knife::CookbookUpload.new
    @knife.name_args = ['test_cookbook']

    @cookbook = Chef::CookbookVersion.new('test_cookbook')

    @cookbook_loader = {}
    @cookbook_loader.stub!(:[]).and_return(@cookbook)
    @cookbook_loader.stub!(:merged_cookbooks).and_return([])
    Chef::CookbookLoader.stub!(:new).and_return(@cookbook_loader)

    @output = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@output)
    @knife.ui.stub!(:stderr).and_return(@output)
  end

  describe 'run' do
    before(:each) do
      @knife.stub!(:upload).and_return(true)
      Chef::CookbookVersion.stub(:list_all_versions).and_return({})
    end

    it 'should print usage and exit when a cookbook name is not provided' do
      @knife.name_args = []
      @knife.should_receive(:show_usage)
      @knife.ui.should_receive(:fatal)
      lambda { @knife.run }.should raise_error(SystemExit)
    end

    describe 'when specifying a cookbook name' do
      it 'should upload the cookbook' do
        @knife.should_receive(:upload).once
        @knife.run
      end

      it 'should report on success' do
        @knife.should_receive(:upload).once
        @knife.ui.should_receive(:info).with(/Uploaded 1 cookbook/)
        @knife.run
      end
    end

    # This is testing too much.  We should break it up.
    describe 'when specifying a cookbook name with dependencies' do
      it "should upload all dependencies once" do
        @knife.name_args = ["test_cookbook2"]
        @knife.config[:depends] = true
        @test_cookbook1 = Chef::CookbookVersion.new('test_cookbook1')
        @test_cookbook2 = Chef::CookbookVersion.new('test_cookbook2')
        @test_cookbook3 = Chef::CookbookVersion.new('test_cookbook3')
        @test_cookbook2.metadata.depends("test_cookbook3")
        @test_cookbook3.metadata.depends("test_cookbook1")
        @test_cookbook3.metadata.depends("test_cookbook2")
        @cookbook_loader.stub!(:[])  do |ckbk|
          { "test_cookbook1" =>  @test_cookbook1,
            "test_cookbook2" =>  @test_cookbook2,
            "test_cookbook3" => @test_cookbook3 }[ckbk]
        end
        @knife.should_receive(:upload).exactly(3).times
        Timeout::timeout(5) do
          @knife.run
        end.should_not raise_error(Timeout::Error)
      end
    end

    it "should freeze the version of the cookbooks if --freeze is specified" do
      @knife.config[:freeze] = true
      @cookbook.should_receive(:freeze_version).once
      @knife.run
    end

    describe 'with -a or --all' do
      before(:each) do
        @knife.config[:all] = true
        @test_cookbook1 = Chef::CookbookVersion.new('test_cookbook1')
        @test_cookbook2 = Chef::CookbookVersion.new('test_cookbook2')
        @cookbook_loader.stub!(:each).and_yield("test_cookbook1", @test_cookbook1).and_yield("test_cookbook2", @test_cookbook2)
        @cookbook_loader.stub!(:cookbook_names).and_return(["test_cookbook1", "test_cookbook2"])
      end

      it 'should upload all cookbooks' do
        @knife.should_receive(:upload).twice
        @knife.run
      end

      it 'should report on success' do
        @knife.should_receive(:upload).twice
        @knife.ui.should_receive(:info).with(/Uploaded 2 cookbooks/)
        @knife.run
      end

      it 'should update the version constraints for an environment' do
        @knife.stub!(:assert_environment_valid!).and_return(true)
        @knife.config[:environment] = "production"
        @knife.should_receive(:update_version_constraints).once
        @knife.run
      end
    end

    describe "check for dependencies" do
      before (:each) do
        @knife.unstub!(:upload)
        Chef::CookbookUploader.stub_chain(:new, :upload_cookbook)
        @knife.stub!(:check_for_broken_dependencies!)
      end

      it "should not run when --skip-dependency-check" do
        @knife.config[:skip_dependency_check] = true
        @knife.should_not_receive(:check_for_dependencies!)
        @knife.run
      end

      it "should run when --skip-dependency-check is not used" do
        @knife.should_receive(:check_for_dependencies!).once
        @knife.run
      end
    end

    describe 'when a frozen cookbook exists on the server' do
      it 'should fail to replace it' do
        @knife.stub!(:upload).and_raise(Chef::Exceptions::CookbookFrozen)
        @knife.ui.should_receive(:error).with(/Failed to upload 1 cookbook/)
        lambda { @knife.run }.should raise_error(SystemExit)
      end

      it 'should not update the version constraints for an environment' do
        @knife.stub!(:assert_environment_valid!).and_return(true)
        @knife.config[:environment] = "production"
        @knife.stub!(:upload).and_raise(Chef::Exceptions::CookbookFrozen)
        @knife.ui.should_receive(:error).with(/Failed to upload 1 cookbook/)
        @knife.ui.should_receive(:warn).with(/Not updating version constraints/)
        @knife.should_not_receive(:update_version_constraints)
        lambda { @knife.run }.should raise_error(SystemExit)
      end
    end
  end
end # run
