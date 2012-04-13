#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Author:: Ho-Sheng Hsiao (<hosh@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

describe Chef::Provider::Service do
  include SpecHelpers::Provider

  let(:new_resource) { Chef::Resource::Service.new("chef") }
  let(:current_resource) { Chef::Resource::Service.new("chef") }
  let(:provider) {  Chef::Provider::Service.new(new_resource, run_context).tap(&with_attributes.call(provider_attributes)) }
  let(:provider_attributes) { { :current_resource= => current_resource } }

  describe "when enabling the service" do
    it "should enable the service if disabled and set the resource as updated" do
      current_resource.enabled(false)
      provider.should_receive(:enable_service).and_return(true)
      provider.action_enable
      provider.new_resource.should be_updated
    end

    it "should not enable the service if already enabled" do
      current_resource.enabled(true)
      provider.should_not_receive(:enable_service).and_return(true)
      provider.action_enable
      provider.new_resource.should_not be_updated
    end
  end


  describe "when disabling the service" do
    it "should disable the service if enabled and set the resource as updated" do
      current_resource.stub!(:enabled).and_return(true)
      provider.should_receive(:disable_service).and_return(true)
      provider.action_disable
      provider.new_resource.should be_updated
    end

    it "should not disable the service if already disabled" do
      current_resource.stub!(:enabled).and_return(false)
      provider.should_not_receive(:disable_service).and_return(true)
      provider.action_disable
      provider.new_resource.should_not be_updated
    end
  end

  describe "action_start" do
    it "should start the service if it isn't running and set the resource as updated" do
      current_resource.running(false)
      provider.should_receive(:start_service).with.and_return(true)
      provider.action_start
      provider.new_resource.should be_updated
    end

    it "should not start the service if already running" do
      current_resource.running(true)
      provider.should_not_receive(:start_service)
      provider.action_start
      provider.new_resource.should_not be_updated
    end
  end

  describe "action_stop" do
    it "should stop the service if it is running and set the resource as updated" do
      current_resource.stub!(:running).and_return(true)
      provider.should_receive(:stop_service).and_return(true)
      provider.action_stop
      provider.new_resource.should be_updated
    end

    it "should not stop the service if it's already stopped" do
      current_resource.stub!(:running).and_return(false)
      provider.should_not_receive(:stop_service).and_return(true)
      provider.action_stop
      provider.new_resource.should_not be_updated
    end
  end

  describe "action_restart" do
    before(:each) do
      current_resource.supports(:restart => true)
    end

    it "should restart the service if it's supported and set the resource as updated" do
      provider.should_receive(:restart_service).and_return(true)
      provider.action_restart
      provider.new_resource.should be_updated
    end

    it "should restart the service even if it isn't running and set the resource as updated" do
      current_resource.stub!(:running).and_return(false)
      provider.should_receive(:restart_service).and_return(true)
      provider.action_restart
      provider.new_resource.should be_updated
    end
  end

  describe "action_reload" do
    before(:each) do
      new_resource.supports(:reload => true)
    end

    it "should raise an exception if reload isn't supported" do
      new_resource.supports(:reload => false)
      new_resource.stub!(:reload_command).and_return(false)
      lambda { provider.action_reload }.should raise_error(Chef::Exceptions::UnsupportedAction)
    end

    it "should reload the service if it is running and set the resource as updated" do
      current_resource.stub!(:running).and_return(true)
      provider.should_receive(:reload_service).and_return(true)
      provider.action_reload
      provider.new_resource.should be_updated
    end

    it "should not reload the service if it's stopped" do
      current_resource.stub!(:running).and_return(false)
      provider.should_not_receive(:reload_service).and_return(true)
      provider.action_stop
      provider.new_resource.should_not be_updated
    end
  end

  context 'when delegating methods to subclasses' do
    def self.should_delegate(_action)
      it "should delegate ##{_action}" do
        lambda { provider.send(_action) }.should raise_error(Chef::Exceptions::UnsupportedAction)
      end
    end

    should_delegate(:enable_service)
    should_delegate(:disable_service)
    should_delegate(:start_service)
    should_delegate(:stop_service)
    should_delegate(:restart_service)
    should_delegate(:reload_service)
  end
end
