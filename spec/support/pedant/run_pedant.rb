#!/usr/bin/env ruby
require 'bundler'
require 'bundler/setup'
require 'chef_zero/server'
require 'rspec/core'
require 'chef/chef_fs/chef_fs_data_store'
require 'chef/chef_fs/config'
require 'tmpdir'
require 'fileutils'
require 'chef/version'

def start_server(chef_repo_path)
  Dir.mkdir(chef_repo_path) if !File.exists?(chef_repo_path)

  # 11.6 and below had a bug where it couldn't create the repo children automatically
  if Chef::VERSION.to_f < 11.8
    %w(clients cookbooks data_bags environments nodes roles users).each do |child|
      Dir.mkdir("#{chef_repo_path}/#{child}") if !File.exists?("#{chef_repo_path}/#{child}")
    end
  end

  # Start the new server
  Chef::Config.repo_mode = 'everything'
  Chef::Config.chef_repo_path = chef_repo_path
  Chef::Config.versioned_cookbooks = true
  chef_fs = Chef::ChefFS::Config.new.local_fs
  data_store = Chef::ChefFS::ChefFSDataStore.new(chef_fs)
  server = ChefZero::Server.new(:port => 8889.upto(9999), :data_store => data_store)#, :log_level => :debug)
  server.start_background
  server
end

tmpdir = Dir.mktmpdir
begin
  # Create chef repository
  chef_repo_path = "#{tmpdir}/repo"

  # Capture setup data into master_chef_repo_path
  server = start_server(chef_repo_path)

  require 'pedant'
  require 'pedant/opensource'

  #Pedant::Config.rerun = true

  Pedant.config.suite = 'api'
  Pedant.config[:config_file] = 'spec/support/pedant/pedant_config.rb'
  Pedant.config.chef_server = server.url
  Pedant.setup([
    '--skip-knife',
    '--skip-validation',
    '--skip-authentication',
    '--skip-authorization',
    '--skip-omnibus'
  ])

  result = RSpec::Core::Runner.run(Pedant.config.rspec_args)

  server.stop if server.running?
ensure
  FileUtils.remove_entry_secure(tmpdir) if tmpdir
end

exit(result)
