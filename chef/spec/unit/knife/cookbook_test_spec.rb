#
# Author:: Stephen Delano (<stephen@opscode.com>)$
# Author:: Matthew Kent (<mkent@magoazul.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.$
# Copyright:: Copyright (c) 2010 Matthew Kent
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

describe Chef::Knife::CookbookTest do
  before(:each) do
    @knife = Chef::Knife::CookbookTest.new
    @cookbooks = []
    %w{tats central_market jimmy_johns pho}.each do |cookbook_name|
      @cookbooks << Chef::CookbookVersion.new(cookbook_name)
    end
  end

  describe "run" do
    it "should test the cookbook" do
      @knife.stub!(:test_cookbook).and_return(true)
      @knife.name_args = ["italian"]
      @knife.should_receive(:test_cookbook).with("italian")
      @knife.run
    end

    it "should test multiple cookbooks when provided" do
      @knife.stub!(:test_cookbook).and_return(true)
      @knife.name_args = ["tats", "jimmy_johns"]
      @knife.should_receive(:test_cookbook).with("tats")
      @knife.should_receive(:test_cookbook).with("jimmy_johns")
      @knife.should_not_receive(:test_cookbook).with("central_market")
      @knife.should_not_receive(:test_cookbook).with("pho")
      @knife.run
    end

    it "should test both ruby and templates" do
      @knife.stub!(:test_ruby).and_return(true)
      @knife.stub!(:test_template).and_return(true)
      @knife.name_args = ["example"]
      Array(Chef::Config[:cookbook_path]).reverse.each do |path|
        @knife.should_receive(:test_ruby).with(File.join(path, "example")).ordered
        @knife.should_receive(:test_templates).with(File.expand_path(File.join(path, "example"))).ordered
      end
      @knife.run
    end

    describe "syntax checks" do
      before(:each) do
        @path = [ File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks")) ]
        @knife.config[:cookbook_path] = @path
        @knife.name_args = ["openldap"]

        Chef::Mixin::Command.stub!(:run_command).and_return(true)

        @cache = Chef::Cache::Checksum.instance
        @cache.reset!("Memory", {})
        Chef::Cache::Checksum.stub(:instance).and_return(@cache)
      end

      it "should execute the ruby syntax check" do
        @knife.stub!(:test_templates).and_return(true)
        Dir[File.join(@path, 'openldap', '**', '*.rb')].each do |file|
          Chef::Mixin::Command.should_receive(:run_command).with({:command =>"ruby -c #{file}", :output_on_failure=>true})
        end
        @knife.run
      end

      it "should execute the erb template syntax check" do
        @knife.stub!(:test_ruby).and_return(true)
        Dir[File.join(@path, 'openldap', '**', '*.erb')].each do |file|
          Chef::Mixin::Command.should_receive(:run_command).with({:command =>"sh -c 'erubis -x #{file} | ruby -c'", :output_on_failure=>true})
        end
        @knife.run
      end

      it "should instantiate the cache for ruby syntax check" do
        @knife.stub!(:test_templates).and_return(true)
        Chef::Cache::Checksum.should_receive(:instance)
        @knife.run
      end

      it "should instantiate the cache for the erb template syntax check" do
        @knife.stub!(:test_ruby).and_return(true)
        Chef::Cache::Checksum.should_receive(:instance)
        @knife.run
      end

      it "should hit the cache and not execute the ruby syntax checks" do
        @knife.stub!(:test_templates).and_return(true)
        @cache.stub!(:lookup_checksum).and_return(true)
        Chef::Mixin::Command.should_not_receive(:run_command)
        @knife.run
      end

      it "should miss when checking the cache and execute the ruby syntax checks" do
        @knife.stub!(:test_templates).and_return(true)
        @cache.stub!(:lookup_checksum).and_return(false)
        Chef::Mixin::Command.should_receive(:run_command).at_least(:once)
        @knife.run
      end

      it "should hit the cache and not execute the erb template syntax checks" do
        @knife.stub!(:test_ruby).and_return(true)
        @cache.stub!(:lookup_checksum).and_return(true)
        Chef::Mixin::Command.should_not_receive(:run_command)
        @knife.run
      end

      it "should miss when checking the cache and execute the erb template syntax checks" do
        @knife.stub!(:test_ruby).and_return(true)
        @cache.stub!(:lookup_checksum).and_return(false)
        Chef::Mixin::Command.should_receive(:run_command).at_least(:once)
        @knife.run
      end

      it "should generate a checksum when the ruby syntax check was successful" do
        @knife.stub!(:test_templates).and_return(true)
        @cache.stub!(:lookup_checksum).and_return(false)
        @cache.should_receive(:generate_checksum).at_least(:once)
        @knife.run
      end

      it "should not generate a checksum when the ruby syntax check fails" do
        @knife.stub!(:test_templates).and_return(true)
        @cache.stub!(:lookup_checksum).and_return(false)
        Chef::Mixin::Command.stub!(:run_command).and_raise(Chef::Exceptions::Exec)
        @cache.should_not_receive(:generate_checksum)
        lambda { @knife.run }.should raise_error(Chef::Exceptions::Exec)
      end

      it "should generate a checksum when the template syntax check was successful" do
        @knife.stub!(:test_ruby).and_return(true)
        @cache.stub!(:lookup_checksum).and_return(false)
        @cache.should_receive(:generate_checksum).at_least(:once)
        @knife.run
      end

      it "should not generate a checksum when the template syntax check fails" do
        @knife.stub!(:test_ruby).and_return(true)
        @cache.stub!(:lookup_checksum).and_return(false)
        Chef::Mixin::Command.stub!(:run_command).and_raise(Chef::Exceptions::Exec)
        @cache.should_not_receive(:generate_checksum)
        lambda { @knife.run }.should raise_error(Chef::Exceptions::Exec)
      end
    end

    describe "with -a or --all" do
      it "should upload all of the cookbooks" do
        @knife.stub!(:test_cookbook).and_return(true)
        @knife.config[:all] = true
        @loader = mock("Chef::CookbookLoader")
        @cookbooks.inject(@loader.stub!(:each)) { |stub, cookbook|
          stub.and_yield(cookbook)
        }
        Chef::CookbookLoader.stub!(:new).and_return(@loader)
        @cookbooks.each do |cookbook|
          @knife.should_receive(:test_cookbook).with(cookbook.name)
        end
        @knife.run
      end
    end

  end
end
