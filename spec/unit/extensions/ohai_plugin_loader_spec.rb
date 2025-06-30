# encoding: utf-8
require 'spec_helper'
require 'chef/log'
require 'ohai'
require 'chef/node'
require_relative '../../../extensions/ohai_plugin_loader'

describe OhaiPluginLoader do
  let(:ohai_system) { double('Ohai::System') }
  let(:node) { Chef::Node.new }
  let(:plugin_data) { { 'test_plugin' => { 'data' => 'test value' } } }
  let(:empty_data) { {} }
  let(:chef_run_context) { double('Chef::RunContext') }
  let(:cookbook_collection) { double('Chef::CookbookCollection') }
  let(:cookbook) { double('Chef::Cookbook') }
  let(:file_path) { '/tmp/test/plugins/test_plugin.rb' }
  let(:plugin_dir) { '/tmp/test/plugins' }

  before do
    allow(Ohai::System).to receive(:new).and_return(ohai_system)
    allow(ohai_system).to receive(:load_plugins)
    allow(ohai_system).to receive(:all_plugins)
    allow(ohai_system).to receive(:run_additional_plugins)
    allow(ohai_system).to receive(:data).and_return(plugin_data)
    allow(Chef).to receive(:run_context).and_return(chef_run_context)
    allow(chef_run_context).to receive(:cookbook_collection).and_return(cookbook_collection)
    allow(Dir).to receive(:exist?).and_return(true)
    allow(Dir).to receive(:glob).and_return([file_path])
    allow(File).to receive(:read).and_return("Ohai.plugin(:TestPlugin) do\n  provides 'test_plugin'\nend")
    allow(File).to receive(:join).and_return(plugin_dir)
    
    # Stub Chef::Config[:file_cache_path]
    allow(Chef::Config).to receive(:[]).with(:file_cache_path).and_return('/tmp/chef/cache')
  end

  describe '#find_plugin_file' do
    it 'finds a plugin file by exact name' do
      expect(OhaiPluginLoader.find_plugin_file('test_plugin')).to eq(file_path)
    end

    it 'returns nil when the plugin file is not found' do
      allow(Dir).to receive(:glob).and_return([])
      expect(OhaiPluginLoader.find_plugin_file('missing_plugin')).to be_nil
    end
    
    it 'finds a plugin by content match' do
      allow(Dir).to receive(:glob).with("#{plugin_dir}/**/unknown_plugin.rb").and_return([])
      allow(Dir).to receive(:glob).with("#{plugin_dir}/**/*.rb").and_return([file_path])
      allow(File).to receive(:read).and_return("Ohai.plugin(:Unknown) do\n  provides 'unknown_plugin'\nend")
      
      expect(OhaiPluginLoader.find_plugin_file('unknown_plugin')).to eq(file_path)
    end
    
    it 'handles errors when reading plugin files' do
      allow(File).to receive(:read).and_raise(StandardError.new('Failed to read file'))
      allow(Chef::Log).to receive(:warn)
      
      expect(OhaiPluginLoader.find_plugin_file('test_plugin')).to be_nil
      expect(Chef::Log).to have_received(:warn).with(/Error reading plugin file/)
    end
  end

  describe '#register_plugin_paths' do
    before do
      # Reset the plugin path before each test
      if Ohai::Config[:plugin_path]
        Ohai::Config[:plugin_path].clear
      else
        Ohai::Config[:plugin_path] = []
      end
      
      allow(OhaiPluginLoader).to receive(:all_plugin_paths).and_return(['/path1', '/path2'])
      allow(Chef::Log).to receive(:info)
    end

    it 'registers all detected plugin paths' do
      OhaiPluginLoader.register_plugin_paths
      
      expect(Ohai::Config[:plugin_path]).to include('/path1', '/path2')
      expect(Chef::Log).to have_received(:info).with(/Registered Ohai plugin paths/)
    end
    
    it 'does not add duplicate paths' do
      Ohai::Config[:plugin_path] << '/path1'
      OhaiPluginLoader.register_plugin_paths
      
      expect(Ohai::Config[:plugin_path].count('/path1')).to eq(1)
    end
  end

  describe '#force_load_all_plugins' do
    before do
      allow(OhaiPluginLoader).to receive(:register_plugin_paths)
    end
    
    it 'registers plugin paths and loads all plugins' do
      result = OhaiPluginLoader.force_load_all_plugins
      
      expect(OhaiPluginLoader).to have_received(:register_plugin_paths)
      expect(ohai_system).to have_received(:load_plugins)
      expect(ohai_system).to have_received(:all_plugins)
      expect(result).to eq(ohai_system)
    end
  end

  describe '#reload_plugin' do
    context 'when the plugin file is found' do
      before do
        allow(OhaiPluginLoader).to receive(:find_plugin_file).with('test_plugin').and_return(file_path)
        allow(OhaiPluginLoader).to receive(:register_plugin_paths)
        allow(Chef::Log).to receive(:info)
      end
      
      it 'loads and runs the specific plugin' do
        result = OhaiPluginLoader.reload_plugin('test_plugin')
        
        expect(ohai_system).to have_received(:load_plugins)
        expect(ohai_system).to have_received(:run_additional_plugins).with(file_path)
        expect(result).to eq(ohai_system)
      end
      
      it 'merges plugin data into node attributes when node is provided' do
        OhaiPluginLoader.reload_plugin('test_plugin', node)
        
        expect(node.automatic_attrs['test_plugin']).to eq(plugin_data['test_plugin'])
      end
    end
    
    context 'when the plugin file is not found' do
      before do
        allow(OhaiPluginLoader).to receive(:find_plugin_file).with('missing_plugin').and_return(nil)
        allow(OhaiPluginLoader).to receive(:register_plugin_paths)
        allow(Chef::Log).to receive(:info)
        allow(Chef::Log).to receive(:warn)
      end
      
      it 'falls back to loading all plugins' do
        OhaiPluginLoader.reload_plugin('missing_plugin')
        
        expect(ohai_system).to have_received(:load_plugins)
        expect(ohai_system).to have_received(:all_plugins)
      end
      
      it 'logs a warning when plugin data is not found' do
        allow(ohai_system).to receive(:data).and_return(empty_data)
        
        OhaiPluginLoader.reload_plugin('missing_plugin')
        
        expect(Chef::Log).to have_received(:warn).with(/Plugin missing_plugin data was not found/)
      end
    end
  end

  describe '#safe_reload_plugin' do
    it 'handles AttributeNotFound errors gracefully' do
      allow(OhaiPluginLoader).to receive(:reload_plugin).and_raise(Ohai::Exceptions::AttributeNotFound.new('No such attribute'))
      allow(OhaiPluginLoader).to receive(:force_load_all_plugins).and_return(ohai_system)
      allow(Chef::Log).to receive(:warn)
      allow(Chef::Log).to receive(:info)
      
      result = OhaiPluginLoader.safe_reload_plugin('problem_plugin')
      
      expect(Chef::Log).to have_received(:warn).with(/AttributeNotFound error for plugin problem_plugin/)
      expect(OhaiPluginLoader).to have_received(:force_load_all_plugins)
      expect(result).to eq(ohai_system)
    end
    
    it 'returns the result of reload_plugin when no errors occur' do
      allow(OhaiPluginLoader).to receive(:reload_plugin).with('good_plugin', node).and_return(ohai_system)
      
      result = OhaiPluginLoader.safe_reload_plugin('good_plugin', node)
      
      expect(OhaiPluginLoader).to have_received(:reload_plugin).with('good_plugin', node)
      expect(result).to eq(ohai_system)
    end
  end

  describe '#register_cookbook_plugins' do
    let(:cookbook_root) { '/cookbook/root' }
    let(:ohai_dir) { '/cookbook/root/ohai' }
    let(:plugin_files) { ['/cookbook/root/ohai/plugin1.rb', '/cookbook/root/ohai/plugin2.rb'] }
    
    before do
      allow(cookbook).to receive(:root_dir).and_return(cookbook_root)
      allow(cookbook_collection).to receive(:[]).with('test_cookbook').and_return(cookbook)
      allow(run_context).to receive(:cookbook_collection).and_return(cookbook_collection)
      allow(Dir).to receive(:exist?).with(ohai_dir).and_return(true)
      allow(Dir).to receive(:glob).with("#{ohai_dir}/**/*.rb").and_return(plugin_files)
      allow(Chef::Log).to receive(:info)
    end
    
    it 'registers plugins from a cookbook' do
      path = OhaiPluginLoader.register_cookbook_plugins(run_context, 'test_cookbook')
      
      expect(path).to eq(ohai_dir)
      expect(Ohai::Config[:plugin_path]).to include(ohai_dir)
      expect(Chef::Log).to have_received(:info).with(/Registering Ohai plugin from cookbook test_cookbook/).twice
    end
    
    it 'returns nil when cookbook does not exist' do
      allow(cookbook_collection).to receive(:[]).with('missing_cookbook').and_return(nil)
      
      path = OhaiPluginLoader.register_cookbook_plugins(run_context, 'missing_cookbook')
      
      expect(path).to be_nil
    end
    
    it 'returns nil when ohai directory does not exist' do
      allow(Dir).to receive(:exist?).with(ohai_dir).and_return(false)
      
      path = OhaiPluginLoader.register_cookbook_plugins(run_context, 'test_cookbook')
      
      expect(path).to be_nil
    end
  end

  describe 'Chef::Resource::Ohai monkey patch' do
    let(:ohai_resource) { Chef::Resource::Ohai.new('test') }
    let(:run_context) { double('Chef::RunContext', node: node) }
    
    before do
      ohai_resource.run_context = run_context
      allow(OhaiPluginLoader).to receive(:safe_reload_plugin).and_return(ohai_system)
      allow(OhaiPluginLoader).to receive(:force_load_all_plugins).and_return(ohai_system)
      allow(ohai_system).to receive(:data).and_return(plugin_data)
      allow(run_context.node.automatic_attrs).to receive(:merge!)
      allow(Chef::Log).to receive(:info)
      allow(ohai_resource).to receive(:converge_by).and_yield
      allow(ohai_resource).to receive(:logger).and_return(Chef::Log)
    end
    
    it 'calls safe_reload_plugin when plugin name is specified' do
      ohai_resource.plugin 'test_plugin'
      ohai_resource.run_action(:reload)
      
      expect(OhaiPluginLoader).to have_received(:safe_reload_plugin).with('test_plugin', node)
    end
    
    it 'calls force_load_all_plugins when no plugin name is specified' do
      ohai_resource.run_action(:reload)
      
      expect(OhaiPluginLoader).to have_received(:force_load_all_plugins)
      expect(node.automatic_attrs).to have_received(:merge!).with(plugin_data)
    end
    
    it 'handles errors gracefully when ignore_failure is set' do
      error = StandardError.new('Test error')
      allow(OhaiPluginLoader).to receive(:safe_reload_plugin).and_raise(error)
      allow(Chef::Log).to receive(:error)
      ohai_resource.plugin 'test_plugin'
      ohai_resource.ignore_failure true
      
      expect { ohai_resource.run_action(:reload) }.not_to raise_error
      expect(Chef::Log).to have_received(:error).with(/Failed to reload Ohai plugin/)
    end
    
    it 're-raises errors when ignore_failure is not set' do
      error = StandardError.new('Test error')
      allow(OhaiPluginLoader).to receive(:safe_reload_plugin).and_raise(error)
      ohai_resource.plugin 'test_plugin'
      
      expect { ohai_resource.run_action(:reload) }.to raise_error(StandardError, 'Test error')
    end
  end

  describe ChefExtensions::OhaiHelper do
    it 'forwards register_cookbook_plugins calls to OhaiPluginLoader' do
      allow(OhaiPluginLoader).to receive(:register_cookbook_plugins)
      
      ChefExtensions::OhaiHelper.register_cookbook_plugins(run_context, 'test_cookbook', 'custom_path')
      
      expect(OhaiPluginLoader).to have_received(:register_cookbook_plugins).with(run_context, 'test_cookbook', 'custom_path')
    end
  end
end
