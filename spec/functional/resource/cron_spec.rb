# encoding: UTF-8
#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
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
require 'chef/mixin/shell_out'

describe Chef::Resource::Cron, :unix_only do

  include Chef::Mixin::ShellOut

  # Order the tests for proper cleanup and execution
  RSpec.configure do |config|
    config.order_groups_and_examples do |list|
      list.sort_by { |item| item.description }
    end
  end

  # User provider is platform-dependent, we need platform ohai data:
  OHAI_SYSTEM = Ohai::System.new
  OHAI_SYSTEM.require_plugin("os")
  OHAI_SYSTEM.require_plugin("platform")
  OHAI_SYSTEM.require_plugin("passwd")

  let(:new_resource) do
    node = Chef::Node.new
    node.default[:platform] = OHAI_SYSTEM[:platform]
    node.default[:platform_version] = OHAI_SYSTEM[:platform_version]
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    new_resource = Chef::Resource::Cron.new("Chef functional test cron", run_context)
    new_resource.user  OHAI_SYSTEM[:current_user]
    new_resource.minute "30"
    new_resource.command "/bin/true"
    new_resource
  end

  let(:provider) do
    provider = new_resource.provider_for_action(new_resource.action)
    provider
  end

  def current_resource
    provider.load_current_resource
    provider.current_resource
  end

  def validate_new_cron_creation
    current_resource.name.should == "Chef functional test cron"
    current_resource.minute.should == "30"
    current_resource.command.should == "/bin/true"
  end

  describe "testcase 1: create action" do
    it "should create a crontab entry" do
      new_resource.run_action(:create)
      validate_new_cron_creation
    end
  end

  describe "testcase 2: delete action" do
    it "should delete a crontab entry" do
      # Note that test cron is created by previous test
      new_resource.run_action(:delete)
      # Verify if the cron is deleted successfully by trying to load it.
      current_resource.command.should be_nil
    end
  end

  describe "testcase 3: create action with various attributes" do
    def create_and_validate
      provider.load_current_resource
      provider.cron_exists.should be_false
      if OHAI_SYSTEM[:platform] == 'aix'
         expect {new_resource.run_action(:create)}.to raise_error(Chef::Exceptions::Cron, /Aix cron entry does not support environment variables. Please set them in script and use script in cron./)
      else
        new_resource.run_action(:create)
        # Verify if the cron is created successfully
        validate_new_cron_creation
      end
    end

    def validate_cron_attribute(attribute, expected_value)
      return if OHAI_SYSTEM[:platform] == 'aix'
      # Test if the attribute exists on newly created cron
      expect(current_resource.send(attribute.to_sym)).to eql(expected_value)
    end

    after do
      new_resource.run_action(:delete)
      # Verify if the cron is deleted successfully
      provider.load_current_resource
      provider.cron_exists.should be_false
    end

    it "should create a crontab entry for mailto attribute" do
      new_resource.mailto "cheftest@example.com"
      create_and_validate
      validate_cron_attribute("mailto", "cheftest@example.com")
    end

    it "should create a crontab entry for path attribute" do
      new_resource.path "/usr/local/bin"
      create_and_validate
      validate_cron_attribute("path", "/usr/local/bin")
    end

    it "should create a crontab entry for shell attribute" do
      new_resource.shell "/bin/bash"
      create_and_validate
      validate_cron_attribute("shell", "/bin/bash")
    end

    it "should create a crontab entry for home attribute" do
      new_resource.home "/home/opscode"
      create_and_validate
      validate_cron_attribute("home", "/home/opscode")
    end
  end

  describe "testcase 4: negative tests for create action" do
    def create_and_validate
      expect { new_resource.run_action(:create) }.to raise_error(Chef::Exceptions::Cron, /Error updating state of #{new_resource.name}, exit: 1/)
    end

    it "should not create cron with invalid minute" do
      new_resource.minute "invalid"
      create_and_validate
    end

    it "should not create cron with invalid user" do
      new_resource.user "1-really-really-invalid-user-name"
      create_and_validate
    end

  end
end