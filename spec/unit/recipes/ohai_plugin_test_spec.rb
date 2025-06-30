# encoding: utf-8
require 'spec_helper'

describe 'win_tester::ohai_plugin_test' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      # Set some node attributes here if needed
    end.converge(described_recipe)
  end

  before do
    # Stub the Ohai system to return controlled data
    allow_any_instance_of(Ohai::System).to receive(:all_plugins).and_return(nil)
    allow_any_instance_of(Ohai::System).to receive(:data).and_return({
      'myplugin' => { 'data' => 'Hello from myplugin!' }
    })
    
    # Stub File.exist? to pretend the plugin file exists
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(anything).and_return(true)
    
    # Stub Dir.exist? for plugin directories
    allow(Dir).to receive(:exist?).and_call_original
    allow(Dir).to receive(:exist?).with(anything).and_return(true)
    
    # Stub Dir.glob to return our test files
    allow(Dir).to receive(:glob).and_call_original
    allow(Dir).to receive(:glob).with(/plugins/).and_return(['/path/to/myplugin.rb'])
    
    # Stub the ohai resource to not really run
    allow_any_instance_of(Chef::Resource::Ohai).to receive(:run_action)
  end

  it 'runs ohai resource with plugin name' do
    expect(chef_run).to reload_ohai('reload_standard').with(
      plugin: 'myplugin',
      ignore_failure: true
    )
  end

  it 'creates the plugin directory' do
    expect(chef_run).to create_directory("#{Chef::Config[:file_cache_path]}/plugins").with(
      recursive: true
    )
  end

  it 'adds the plugin file from cookbook' do
    expect(chef_run).to create_cookbook_file("#{Chef::Config[:file_cache_path]}/plugins/myplugin.rb").with(
      source: 'plugins/myplugin.rb'
    )
  end

  it 'notifies reload_all_plugins' do
    resource = chef_run.cookbook_file("#{Chef::Config[:file_cache_path]}/plugins/myplugin.rb")
    expect(resource).to notify('ruby_block[reload_all_plugins]').immediately
  end

  it 'runs the plugin data print block' do
    expect(chef_run).to run_ruby_block('print_plugin_data_after_reload')
  end

  it 'registers plugin paths' do
    expect(chef_run).to run_ruby_block('ensure_plugin_paths_registered')
  end
end
