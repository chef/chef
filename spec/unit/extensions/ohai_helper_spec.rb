# encoding: utf-8
require 'spec_helper'
require 'chef/log'
require 'ohai'
require 'chef/node'
require_relative '../../../libraries/ohai_helper'

describe ChefExtensions::OhaiHelper do
  let(:run_context) { double('Chef::RunContext') }
  let(:cookbook_collection) { double('Chef::CookbookCollection') }
  let(:cookbook) { double('Chef::Cookbook') }
  let(:node) { Chef::Node.new }
  let(:ohai_system) { double('Ohai::System') }
  let(:plugin_data) { { 'test_plugin' => { 'data' => 'test value' } } }

  before do
    allow(run_context).to receive(:cookbook_collection).and_return(cookbook_collection)
    allow(cookbook_collection).to receive(:[]).with('test_cookbook').and_return(cookbook)
    allow(cookbook).to receive(:root_dir).and_return('/cookbook/root')
    allow(Ohai::System).to receive(:new).and_return(ohai_system)
    allow(ohai_system).to receive(:load_plugins)
    allow(ohai_system).to receive(:run_additional_plugins)
    allow(ohai_system).to receive(:run_plugins)
    allow(ohai_system).to receive(:all_plugins)
    allow(ohai_system).to receive(:data).and_return(plugin_data)
    allow(Chef::Log).to receive(:info)
    allow(Chef::Log).to receive(:debug)
    allow(Chef::Log).to receive(:warn)
  end

  describe '.register_cookbook_plugins' do
    it 'delegates to OhaiPluginLoader.register_cookbook_plugins' do
      allow(OhaiPluginLoader).to receive(:register_cookbook_plugins)
      
      ChefExtensions::OhaiHelper.register_cookbook_plugins(run_context, 'test_cookbook', 'custom_path')
      
      expect(OhaiPluginLoader).to have_received(:register_cookbook_plugins).with(run_context, 'test_cookbook', 'custom_path')
    end

    it 'uses default path when not specified' do
      allow(OhaiPluginLoader).to receive(:register_cookbook_plugins)
      
      ChefExtensions::OhaiHelper.register_cookbook_plugins(run_context, 'test_cookbook')
      
      expect(OhaiPluginLoader).to have_received(:register_cookbook_plugins).with(run_context, 'test_cookbook', 'ohai')
    end
  end

  describe '.find_plugin_by_name' do
    before do
      Ohai::Config[:plugin_path] = ['/path1', '/path2']
      allow(File).to receive(:directory?).and_return(true)
      allow(Dir).to receive(:glob).and_return(['/path1/test_plugin.rb'])
      allow(File).to receive(:read).and_return("Ohai.plugin(:TestPlugin) do\n  provides 'test_plugin'\nend")
    end

    it 'finds a plugin by name in configured paths' do
      result = ChefExtensions::OhaiHelper.find_plugin_by_name('test_plugin')
      
      expect(result).to eq('/path1/test_plugin.rb')
    end

    it 'returns nil when plugin is not found' do
      allow(File).to receive(:read).and_return("some other content")
      
      result = ChefExtensions::OhaiHelper.find_plugin_by_name('missing_plugin')
      
      expect(result).to be_nil
    end

    it 'skips non-existent directories' do
      allow(File).to receive(:directory?).with('/path1').and_return(false)
      allow(File).to receive(:directory?).with('/path2').and_return(true)
      allow(Dir).to receive(:glob).with('/path2/**/*.rb').and_return(['/path2/test_plugin.rb'])
      
      result = ChefExtensions::OhaiHelper.find_plugin_by_name('test_plugin')
      
      expect(result).to eq('/path2/test_plugin.rb')
    end
  end

  describe '.reload_plugin_file' do
    let(:plugin_file) { '/path/to/plugin.rb' }

    it 'creates an Ohai system and loads the specific plugin' do
      result = ChefExtensions::OhaiHelper.reload_plugin_file(plugin_file, node)
      
      expect(ohai_system).to have_received(:load_plugins)
      expect(ohai_system).to have_received(:run_additional_plugins).with(plugin_file)
      expect(result).to eq(ohai_system)
    end

    it 'merges plugin data into node when provided' do
      ChefExtensions::OhaiHelper.reload_plugin_file(plugin_file, node)
      
      expect(node.automatic_attrs['test_plugin']).to eq(plugin_data['test_plugin'])
      expect(Chef::Log).to have_received(:info).with("Ohai plugin reloaded: #{plugin_file}")
    end

    it 'does not merge data when node is not provided' do
      result = ChefExtensions::OhaiHelper.reload_plugin_file(plugin_file)
      
      expect(result).to eq(ohai_system)
      expect(Chef::Log).not_to have_received(:info).with(/Ohai plugin reloaded/)
    end

    it 'does not merge when ohai data is empty' do
      allow(ohai_system).to receive(:data).and_return({})
      
      ChefExtensions::OhaiHelper.reload_plugin_file(plugin_file, node)
      
      expect(Chef::Log).not_to have_received(:info).with(/Ohai plugin reloaded/)
    end
  end

  describe '.reload_all_plugins_in_path' do
    let(:plugin_path) { '/path/to/plugins' }

    before do
      allow(File).to receive(:directory?).with(plugin_path).and_return(true)
      Ohai::Config[:plugin_path] = []
    end

    it 'adds path to Ohai config and loads all plugins' do
      result = ChefExtensions::OhaiHelper.reload_all_plugins_in_path(plugin_path, node)
      
      expect(Ohai::Config[:plugin_path]).to include(plugin_path)
      expect(ohai_system).to have_received(:load_plugins)
      expect(ohai_system).to have_received(:run_plugins).with(true)
      expect(result).to eq(ohai_system)
    end

    it 'merges plugin data into node when provided' do
      ChefExtensions::OhaiHelper.reload_all_plugins_in_path(plugin_path, node)
      
      expect(node.automatic_attrs['test_plugin']).to eq(plugin_data['test_plugin'])
      expect(Chef::Log).to have_received(:info).with("All Ohai plugins reloaded from: #{plugin_path}")
    end

    it 'returns nil when path does not exist' do
      allow(File).to receive(:directory?).with(plugin_path).and_return(false)
      
      result = ChefExtensions::OhaiHelper.reload_all_plugins_in_path(plugin_path, node)
      
      expect(result).to be_nil
    end

    it 'does not add duplicate paths' do
      Ohai::Config[:plugin_path] << plugin_path
      
      ChefExtensions::OhaiHelper.reload_all_plugins_in_path(plugin_path, node)
      
      expect(Ohai::Config[:plugin_path].count(plugin_path)).to eq(1)
    end
  end

  describe '.reload_plugin_by_name' do
    it 'finds and reloads a plugin by name' do
      plugin_file = '/path/to/test_plugin.rb'
      allow(ChefExtensions::OhaiHelper).to receive(:find_plugin_by_name).with('test_plugin').and_return(plugin_file)
      allow(ChefExtensions::OhaiHelper).to receive(:reload_plugin_file).with(plugin_file, node).and_return(ohai_system)
      
      result = ChefExtensions::OhaiHelper.reload_plugin_by_name('test_plugin', node)
      
      expect(ChefExtensions::OhaiHelper).to have_received(:find_plugin_by_name).with('test_plugin')
      expect(ChefExtensions::OhaiHelper).to have_received(:reload_plugin_file).with(plugin_file, node)
      expect(Chef::Log).to have_received(:info).with("Found plugin test_plugin at #{plugin_file}")
      expect(result).to eq(ohai_system)
    end

    it 'returns nil when plugin is not found' do
      allow(ChefExtensions::OhaiHelper).to receive(:find_plugin_by_name).with('missing_plugin').and_return(nil)
      
      result = ChefExtensions::OhaiHelper.reload_plugin_by_name('missing_plugin', node)
      
      expect(result).to be_nil
    end
  end
end

describe Chef::Resource::OhaiPlugin do
  let(:resource) { Chef::Resource::OhaiPlugin.new('test_ohai_plugin') }
  let(:run_context) { double('Chef::RunContext', node: Chef::Node.new) }
  let(:ohai_system) { double('Ohai::System') }

  before do
    resource.run_context = run_context
    allow(resource).to receive(:converge_by).and_yield
    allow(resource).to receive(:logger).and_return(Chef::Log)
    allow(Chef::Log).to receive(:info)
    allow(Chef::Log).to receive(:warn)
    allow(ChefExtensions::OhaiHelper).to receive(:reload_plugin_file).and_return(ohai_system)
    allow(ChefExtensions::OhaiHelper).to receive(:reload_all_plugins_in_path).and_return(ohai_system)
    allow(ChefExtensions::OhaiHelper).to receive(:register_cookbook_plugins).and_return('/cookbook/root/ohai')
    allow(ChefExtensions::OhaiHelper).to receive(:reload_plugin_by_name).and_return(ohai_system)
    allow(File).to receive(:exist?).and_return(true)
    allow(File).to receive(:directory?).and_return(true)
    allow(Ohai::System).to receive(:new).and_return(ohai_system)
    allow(ohai_system).to receive(:all_plugins)
    allow(ohai_system).to receive(:data).and_return({})
    allow(run_context.node.automatic_attrs).to receive(:merge!)
  end

  describe 'action :reload' do
    it 'reloads plugin by file when plugin_file is specified' do
      resource.plugin_file '/path/to/plugin.rb'
      
      resource.run_action(:reload)
      
      expect(ChefExtensions::OhaiHelper).to have_received(:reload_plugin_file).with('/path/to/plugin.rb', run_context.node)
    end

    it 'reloads plugins from path when plugin_path is specified' do
      resource.plugin_path '/path/to/plugins'
      
      resource.run_action(:reload)
      
      expect(ChefExtensions::OhaiHelper).to have_received(:reload_all_plugins_in_path).with('/path/to/plugins', run_context.node)
    end

    it 'registers cookbook plugins when plugin_cookbook is specified' do
      resource.plugin_cookbook 'test_cookbook'
      
      resource.run_action(:reload)
      
      expect(ChefExtensions::OhaiHelper).to have_received(:register_cookbook_plugins).with(run_context, 'test_cookbook', 'ohai')
    end

    it 'uses custom cookbook plugin path when specified' do
      resource.plugin_cookbook 'test_cookbook'
      resource.cookbook_plugin_path 'custom_path'
      
      resource.run_action(:reload)
      
      expect(ChefExtensions::OhaiHelper).to have_received(:register_cookbook_plugins).with(run_context, 'test_cookbook', 'custom_path')
    end

    it 'reloads plugin by name when only plugin name is specified' do
      resource.plugin 'test_plugin'
      
      resource.run_action(:reload)
      
      expect(ChefExtensions::OhaiHelper).to have_received(:reload_plugin_by_name).with('test_plugin', run_context.node)
    end

    it 'falls back to all_plugins when plugin name lookup fails' do
      resource.plugin 'missing_plugin'
      allow(ChefExtensions::OhaiHelper).to receive(:reload_plugin_by_name).and_return(nil)
      
      resource.run_action(:reload)
      
      expect(ohai_system).to have_received(:all_plugins).with('missing_plugin')
    end

    it 'falls back to loading all plugins when no specific method succeeds' do
      resource.run_action(:reload)
      
      expect(ohai_system).to have_received(:all_plugins)
    end
  end
end
