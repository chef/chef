#
# Author:: Matthew Kent (<mkent@magoazul.com>)
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

describe Chef::Knife::CookbookUpload do
  before(:each) do
    @knife = Chef::Knife::CookbookUpload.new
    @knife.name_args = ['test_cookbook']

    @cookbook = Chef::CookbookVersion.new('test_cookbook')

    @cookbook_loader = mock('Chef::CookbookLoader')
    @cookbook_loader.stub!(:[]).and_return(@cookbook)
    @cookbook_loader.stub!(:merged_cookbooks).and_return([])
    Chef::CookbookLoader.stub!(:new).and_return(@cookbook_loader)

    @stdout = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
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

      # TODO: many more specs!
    end

  end # run
end
