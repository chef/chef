#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Author:: Scott Bonds (scott@ggr.com)
# Author:: Joe Miller (<joeym@joeym.net>)
# Copyright:: Copyright (c) 2009 Bryan McLellan
# Copyright:: Copyright (c) 2014 Scott Bonds
# Copyright:: Copyright (c) 2015 Joe Miller
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

class Chef::Provider::Service::OpenbsdRcctl
  public :enable_service
  public :disable_service
  public :determine_current_parameters!
  public :parameters_need_update?
  public :update_params!
end

describe Chef::Provider::Service::OpenbsdRcctl do
  let(:node) { Chef::Node.new }

  let(:new_resource) do
    new_resource = Chef::Resource::Service.new('sndiod')
    new_resource.pattern('sndiod')
    new_resource
  end

  let(:current_resource) do
    current_resource = Chef::Resource::Service.new('sndiod')
    current_resource
  end

  let(:provider) do
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    provider = Chef::Provider::Service::OpenbsdRcctl.new(new_resource, run_context)
    provider.action = :start
    provider
  end

  describe 'determine_current_parameters!' do
    before(:each) do
      provider.current_resource = current_resource
      rcctl_output = ["#{new_resource.service_name}_flags=",
                      "#{new_resource.service_name}_timeout=30",
                      "#{new_resource.service_name}_user=root"].join("\n")
      allow(provider).to receive(:shell_out!).with("rcctl get #{new_resource.service_name}", anything).and_return(
        instance_double('shellout', stdout: rcctl_output))
    end

    it 'should load the current_parameters from rcctl' do
      provider.determine_current_parameters!
      expect(current_resource.parameters).to include('flags' => '', 'timeout' => '30', 'user' => 'root')
    end
  end

  describe 'parameters_need_update?' do
    before(:each) do
      provider.current_resource = current_resource
      current_resource.parameters('flags' => 'foo', 'timeout' => '30', 'user' => 'root')
    end

    context 'when new parameters are nil' do
      it 'should return false' do
        provider.new_resource.parameters nil
        expect(provider.parameters_need_update?).to be false
      end
    end

    context 'when all new parameters match all current parameters' do
      it 'should return false' do
        provider.new_resource.parameters current_resource.parameters
        expect(provider.parameters_need_update?).to be false
      end
    end

    context 'when a single new parameter is different than current parameters' do
      it 'should return true' do
        provider.new_resource.parameters('flags' => 'new flags')
        expect(provider.parameters_need_update?).to be true
      end
    end

    context 'when multiple new parameters are specified and only one is different than current parameters' do
      it 'should return true' do
        provider.new_resource.parameters('flags' => 'new flags', 'user' => 'root')
        expect(provider.parameters_need_update?).to be true
      end
    end
  end

  describe 'define_resource_requirements' do
    context 'when the service does not exist' do
      before do
        provider.current_resource = current_resource
        allow(provider).to receive(:rcctl_status).and_return(2)
      end

      %w(start reload restart enable status).each do |action|
        it "should raise an exception when the action is #{action}" do
          provider.define_resource_requirements
          provider.action = action
          expect { provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Service)
        end
      end

      %w(stop disable).each do |action|
        it "should not raise an error when the action is #{action}" do
          provider.define_resource_requirements
          provider.action = action
          expect { provider.process_resource_requirements }.not_to raise_error
        end
      end
    end

    context 'when the service exists' do
      before do
        provider.current_resource = current_resource
        allow(provider).to receive(:rcctl_status).and_return(0)
      end

      %w(start reload restart enable status stop disable).each do |action|
        it "should not raise an exception when the action is #{action}" do
          provider.define_resource_requirements
          provider.action = action
          expect { provider.process_resource_requirements }.not_to raise_error
        end
      end
    end
  end

  describe 'update_params!' do
    before(:each) do
      provider.new_resource = new_resource
    end

    it 'should call "rcctl set" to update parameters' do
      provider.new_resource.parameters('flags' => 'foo')
      expect(provider).to receive(:shell_out!).with("rcctl set #{new_resource.service_name} \"flags\" \"foo\"")
      provider.update_params!
    end
  end

  context 'when testing actions' do
    before(:each) do
      # provider.current_resource = current_resource
      # provider.new_resource = new_resource
      expect(provider).to receive(:determine_current_status!)
      expect(provider).to receive(:determine_current_parameters!)
      expect(provider).to receive(:is_enabled?)
      current_resource.running false
      current_resource.enabled false
      provider.load_current_resource
    end

    describe 'action_enable' do
      before(:each) do
        provider.current_resource.enabled false
        expect(provider).to receive(:load_new_resource_state)
      end

      context 'when parameters need updating' do
        before(:each) do
          allow(provider).to receive(:parameters_need_update?).and_return(true)
        end

        it 'should update parameters and enable the service' do
          expect(provider).to receive(:update_params!)
          expect(provider).to receive(:enable_service)
          provider.action_enable
          expect(provider.new_resource.enabled).to eq true
        end
      end

      context 'when parameters are up to date' do
        before(:each) do
          provider.current_resource.enabled true
          allow(provider).to receive(:parameters_need_update?).and_return(false)
        end

        it 'should not update parameters' do
          expect(provider).not_to receive(:update_params!)
          expect(provider).not_to receive(:enable_service)
          provider.action_enable
        end
      end
    end

    describe 'disable_service' do
      it 'should execute "rcctl disable" on the service if it is enabled' do
        provider.current_resource.enabled true
        expect(provider).to receive(:shell_out!).with("rcctl disable #{new_resource.service_name}")
        provider.disable_service
      end
    end

    describe 'start_service' do
      it 'should execute "rcctl start" on the service' do
        provider.current_resource.running false
        expect(provider).to receive(:shell_out_with_systems_locale!).with(new_resource.start_command)
        provider.start_service
      end
    end

  end
end
