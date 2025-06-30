# encoding: utf-8
require 'spec_helper'
require 'chef/resource/ohai'
require 'chef/node'
require_relative '../../../extensions/ohai_plugin_loader'

describe Chef::Resource::Ohai do
  let(:resource) { Chef::Resource::Ohai.new('reload_ohai') }
  let(:run_context) { double('Chef::RunContext', node: Chef::Node.new) }
  let(:ohai_system) { double('Ohai::System') }
  let(:plugin_data) { { 'test_plugin' => { 'data' => 'test value' } } }

  before do
    resource.run_context = run_context
    allow(resource).to receive(:converge_by).and_yield
    allow(resource).to receive(:logger).and_return(Chef::Log)
    allow(Chef::Log).to receive(:info)
    allow(Chef::Log).to receive(:error)
    allow(Chef::Extensions::OhaiPluginLoader).to receive(:safe_reload_plugin).and_return(ohai_system)
    allow(Chef::Extensions::OhaiPluginLoader).to receive(:force_load_all_plugins).and_return(ohai_system)
    allow(ohai_system).to receive(:data).and_return(plugin_data)
    allow(run_context.node.automatic_attrs).to receive(:merge!)
  end

  describe 'properties' do
    it 'has a plugin property' do
      resource.plugin 'test_plugin'
      expect(resource.plugin).to eq('test_plugin')
    end

    it 'has an ignore_failure property with default false' do
      expect(resource.ignore_failure).to eq(false)
    end

    it 'allows setting ignore_failure to true' do
      resource.ignore_failure true
      expect(resource.ignore_failure).to eq(true)
    end
  end

  describe 'action :reload' do
    context 'when a specific plugin is requested' do
      before do
        resource.plugin 'test_plugin'
      end

      it 'calls safe_reload_plugin with the plugin name and node' do
        resource.run_action(:reload)
        
        expect(Chef::Extensions::OhaiPluginLoader).to have_received(:safe_reload_plugin).with('test_plugin', run_context.node)
        expect(Chef::Log).to have_received(:info).with('Reloading Ohai plugin: test_plugin')
      end

      it 'logs successful reload' do
        resource.run_action(:reload)
        
        expect(resource.logger).to have_received(:info).with(/reload_ohai reloaded/)
      end
    end

    context 'when no specific plugin is requested' do
      it 'calls force_load_all_plugins and merges data' do
        resource.run_action(:reload)
        
        expect(Chef::Extensions::OhaiPluginLoader).to have_received(:force_load_all_plugins)
        expect(run_context.node.automatic_attrs).to have_received(:merge!).with(plugin_data)
        expect(Chef::Log).to have_received(:info).with('Reloading all Ohai plugins')
      end
    end

    context 'when an error occurs' do
      let(:test_error) { StandardError.new('Test error') }

      before do
        resource.plugin 'problem_plugin'
        allow(Chef::Extensions::OhaiPluginLoader).to receive(:safe_reload_plugin).and_raise(test_error)
      end

      context 'and ignore_failure is false' do
        it 'raises the error' do
          expect { resource.run_action(:reload) }.to raise_error(StandardError, 'Test error')
        end
      end

      context 'and ignore_failure is true' do
        before do
          resource.ignore_failure true
        end

        it 'logs the error and continues' do
          expect { resource.run_action(:reload) }.not_to raise_error
          
          expect(Chef::Log).to have_received(:error).with('Failed to reload Ohai plugin: StandardError: Test error')
          expect(Chef::Log).to have_received(:error).with('Ignoring failure and continuing.')
        end
      end
    end
  end

  describe 'backward compatibility' do
    it 'maintains the original property definition' do
      resource.plugin 'ipaddress'
      expect(resource.plugin).to eq('ipaddress')
    end

    it 'supports the original examples from documentation' do
      # Example 1: Reload all plugins
      reload_all = Chef::Resource::Ohai.new('reload')
      reload_all.run_context = run_context
      allow(reload_all).to receive(:converge_by).and_yield
      allow(reload_all).to receive(:logger).and_return(Chef::Log)
      
      expect { reload_all.run_action(:reload) }.not_to raise_error
      expect(Chef::Extensions::OhaiPluginLoader).to have_received(:force_load_all_plugins)

      # Example 2: Reload specific plugin
      reload_specific = Chef::Resource::Ohai.new('reload')
      reload_specific.plugin 'ipaddress'
      reload_specific.run_context = run_context
      allow(reload_specific).to receive(:converge_by).and_yield
      allow(reload_specific).to receive(:logger).and_return(Chef::Log)
      
      expect { reload_specific.run_action(:reload) }.not_to raise_error
      expect(Chef::Extensions::OhaiPluginLoader).to have_received(:safe_reload_plugin).with('ipaddress', run_context.node)
    end
  end

  describe 'integration with OhaiPluginLoader' do
    it 'uses the enhanced plugin loader for better reliability' do
      resource.plugin 'custom_plugin'
      
      resource.run_action(:reload)
      
      expect(Chef::Extensions::OhaiPluginLoader).to have_received(:safe_reload_plugin)
      expect(Chef::Extensions::OhaiPluginLoader).not_to have_received(:force_load_all_plugins)
    end

    it 'handles AttributeNotFound errors through the safe loader' do
      # The safe_reload_plugin method should handle AttributeNotFound internally
      # This test verifies that the resource properly delegates to the safe method
      allow(Chef::Extensions::OhaiPluginLoader).to receive(:safe_reload_plugin).and_return(ohai_system)
      
      resource.plugin 'problematic_plugin'
      resource.run_action(:reload)
      
      expect(Chef::Extensions::OhaiPluginLoader).to have_received(:safe_reload_plugin).with('problematic_plugin', run_context.node)
    end
  end
end
