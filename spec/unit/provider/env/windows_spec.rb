#
# Author:: Sander van Harmelen <svanharmelen@schubergphilis.com>
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

describe Chef::Provider::Env::Windows, :windows_only do
  before do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Env.new("CHEF_WINDOWS_ENV_TEST")
    @new_resource.value("foo")
    @provider = Chef::Provider::Env::Windows.new(@new_resource, @run_context)
    @provider.stub(:env_obj).and_return(double('null object').as_null_object)
  end

  describe "action_create" do
    before do
      ENV.delete('CHEF_WINDOWS_ENV_TEST')
      @provider.key_exists = false
    end

    it "should update the ruby ENV object when it creates the key" do
      @provider.action_create
      expect(ENV['CHEF_WINDOWS_ENV_TEST']).to eql('foo')
    end
  end

  describe "action_modify" do
    before do
      ENV['CHEF_WINDOWS_ENV_TEST'] = 'foo'
    end

    it "should update the ruby ENV object when it updates the value" do
      @provider.should_receive(:compare_value).and_return(true)
      @new_resource.value("foobar")
      @provider.action_modify
      expect(ENV['CHEF_WINDOWS_ENV_TEST']).to eql('foobar')
    end
  end

  describe "action_delete" do
    before do
      ENV['CHEF_WINDOWS_ENV_TEST'] = 'foo'
    end

    it "should update the ruby ENV object when it deletes the key" do
      @provider.action_delete
      expect(ENV['CHEF_WINDOWS_ENV_TEST']).to eql(nil)
    end
  end
end
