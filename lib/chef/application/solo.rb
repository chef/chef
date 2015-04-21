#
# Author:: AJ Christensen (<aj@opscode.com>)
# Author:: Mark Mzyk (mmzyk@opscode.com)
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

require 'chef'
require 'chef/application'
require 'chef/client'
require 'chef/config'
require 'chef/daemon'
require 'chef/log'
require 'chef/rest'
require 'chef/config_fetcher'
require 'fileutils'

class Chef::Application::Solo < Chef::Application

  option :config_file,
    :short => "-c CONFIG",
    :long  => "--config CONFIG",
    :default => Chef::Config.platform_specific_path('/etc/chef/solo.rb'),
    :description => "The configuration file to use"

  option :formatter,
    :short        => "-F FORMATTER",
    :long         => "--format FORMATTER",
    :description  => "output format to use",
    :proc         => lambda { |format| Chef::Config.add_formatter(format) }

  option :force_logger,
    :long         => "--force-logger",
    :description  => "Use logger output instead of formatter output",
    :boolean      => true,
    :default      => false

  option :force_formatter,
    :long         => "--force-formatter",
    :description  => "Use formatter output instead of logger output",
    :boolean      => true,
    :default      => false

  option :color,
    :long         => '--[no-]color',
    :boolean      => true,
    :default      => !Chef::Platform.windows?,
    :description  => "Use colored output, defaults to enabled"

  option :log_level,
    :short        => "-l LEVEL",
    :long         => "--log_level LEVEL",
    :description  => "Set the log level (debug, info, warn, error, fatal)",
    :proc         => lambda { |l| l.to_sym }

  option :log_location,
    :short        => "-L LOGLOCATION",
    :long         => "--logfile LOGLOCATION",
    :description  => "Set the log file location, defaults to STDOUT",
    :proc         => nil

  option :help,
    :short        => "-h",
    :long         => "--help",
    :description  => "Show this message",
    :on           => :tail,
    :boolean      => true,
    :show_options => true,
    :exit         => 0

  option :user,
    :short => "-u USER",
    :long => "--user USER",
    :description => "User to set privilege to",
    :proc => nil

  option :group,
    :short => "-g GROUP",
    :long => "--group GROUP",
    :description => "Group to set privilege to",
    :proc => nil

  unless Chef::Platform.windows?
    option :daemonize,
      :short => "-d",
      :long => "--daemonize",
      :description => "Daemonize the process",
      :proc => lambda { |p| true }
  end

  option :lockfile,
    :long         => "--lockfile LOCKFILE",
    :description  => "Set the lockfile location. Prevents multiple processes from converging at the same time",
    :proc         => nil

  option :interval,
    :short => "-i SECONDS",
    :long => "--interval SECONDS",
    :description => "Run chef-client periodically, in seconds",
    :proc => lambda { |s| s.to_i }

  option :json_attribs,
    :short => "-j JSON_ATTRIBS",
    :long => "--json-attributes JSON_ATTRIBS",
    :description => "Load attributes from a JSON file or URL",
    :proc => nil

  option :node_name,
    :short => "-N NODE_NAME",
    :long => "--node-name NODE_NAME",
    :description => "The node name for this client",
    :proc => nil

  option :splay,
    :short => "-s SECONDS",
    :long => "--splay SECONDS",
    :description => "The splay time for running at intervals, in seconds",
    :proc => lambda { |s| s.to_i }

  option :recipe_url,
      :short => "-r RECIPE_URL",
      :long => "--recipe-url RECIPE_URL",
      :description => "Pull down a remote gzipped tarball of recipes and untar it to the cookbook cache.",
      :proc => nil

  option :version,
    :short        => "-v",
    :long         => "--version",
    :description  => "Show chef version",
    :boolean      => true,
    :proc         => lambda {|v| puts "Chef: #{::Chef::VERSION}"},
    :exit         => 0

  option :override_runlist,
    :short        => "-o RunlistItem,RunlistItem...",
    :long         => "--override-runlist RunlistItem,RunlistItem...",
    :description  => "Replace current run list with specified items",
    :proc         => lambda{|items|
      items = items.split(',')
      items.compact.map{|item|
        Chef::RunList::RunListItem.new(item)
      }
    }

  option :client_fork,
    :short        => "-f",
    :long         => "--[no-]fork",
    :description  => "Fork client",
    :boolean      => true

  option :why_run,
    :short        => '-W',
    :long         => '--why-run',
    :description  => 'Enable whyrun mode',
    :boolean      => true

  option :ez,
    :long         => '--ez',
    :description  => 'A memorial for Ezra Zygmuntowicz',
    :boolean      => true

  option :environment,
    :short        => '-E ENVIRONMENT',
    :long         => '--environment ENVIRONMENT',
    :description  => 'Set the Chef Environment on the node'

  option :run_lock_timeout,
    :long         => "--run-lock-timeout SECONDS",
    :description  => "Set maximum duration to wait for another client run to finish, default is indefinitely.",
    :proc         => lambda { |s| s.to_i }

  option :minimal_ohai,
    :long           => "--minimal-ohai",
    :description    => "Only run the bare minimum ohai plugins chef needs to function",
    :boolean        => true

  attr_reader :chef_client_json

  def initialize
    super
  end

  def reconfigure
    super

    set_specific_recipes

    Chef::Config[:solo] = true

    if Chef::Config[:daemonize]
      Chef::Config[:interval] ||= 1800
    end

    Chef::Application.fatal!(unforked_interval_error_message) if !Chef::Config[:client_fork] && Chef::Config[:interval]

    if Chef::Config[:recipe_url]
      cookbooks_path = Array(Chef::Config[:cookbook_path]).detect{|e| e =~ /\/cookbooks\/*$/ }
      recipes_path = File.expand_path(File.join(cookbooks_path, '..'))

      Chef::Log.debug "Cleanup path #{recipes_path} before extract recipes into it"
      FileUtils.rm_rf(recipes_path, :secure => true)
      Chef::Log.debug "Creating path #{recipes_path} to extract recipes into"
      FileUtils.mkdir_p(recipes_path)
      tarball_path = File.join(recipes_path, 'recipes.tgz')
      fetch_recipe_tarball(Chef::Config[:recipe_url], tarball_path)
      Chef::Mixin::Command.run_command(:command => "tar zxvf #{tarball_path} -C #{recipes_path}")
    end

    # json_attribs shuld be fetched after recipe_url tarball is unpacked.
    # Otherwise it may fail if points to local file from tarball.
    if Chef::Config[:json_attribs]
      config_fetcher = Chef::ConfigFetcher.new(Chef::Config[:json_attribs])
      @chef_client_json = config_fetcher.fetch_json
    end

    # Disable auditing for solo
    Chef::Config[:audit_mode] = :disabled
  end

  def setup_application
    Chef::Daemon.change_privilege
  end

  def run_application
    for_ezra if Chef::Config[:ez]
    if !Chef::Config[:client_fork] || Chef::Config[:once]
      # Run immediately without interval sleep or splay
      begin
        run_chef_client(Chef::Config[:specific_recipes])
      rescue SystemExit
        raise
      rescue Exception => e
        Chef::Application.fatal!("#{e.class}: #{e.message}", 1)
      end
    else
      interval_run_chef_client
    end
  end


  private

  def for_ezra
    puts <<-EOH
For Ezra Zygmuntowicz:
  The man who brought you Chef Solo
  Early contributor to Chef
  Kind hearted open source advocate
  Rest in peace, Ezra.
EOH
  end

  def interval_run_chef_client
    if Chef::Config[:daemonize]
      Chef::Daemon.daemonize("chef-client")
    end

    loop do
      begin

        sleep_sec = 0
        sleep_sec += rand(Chef::Config[:splay]) if Chef::Config[:splay]
        sleep_sec += Chef::Config[:interval] if Chef::Config[:interval]
        if sleep_sec != 0
          Chef::Log.debug("Sleeping for #{sleep_sec} seconds")
          sleep(sleep_sec)
        end

        run_chef_client
        if !Chef::Config[:interval]
          Chef::Application.exit! "Exiting", 0
        end
      rescue SystemExit => e
        raise
      rescue Exception => e
        if Chef::Config[:interval]
          Chef::Log.error("#{e.class}: #{e}")
          Chef::Log.debug("#{e.class}: #{e}\n#{e.backtrace.join("\n")}")
          retry
        else
          Chef::Application.fatal!("#{e.class}: #{e.message}", 1)
        end
      end
    end
  end

  def fetch_recipe_tarball(url, path)
    Chef::Log.debug("Download recipes tarball from #{url} to #{path}")
    File.open(path, 'wb') do |f|
      open(url) do |r|
        f.write(r.read)
      end
    end
  end

  def unforked_interval_error_message
    "Unforked chef-client interval runs are disabled in Chef 12." +
    "\nConfiguration settings:" +
    "#{"\n  interval  = #{Chef::Config[:interval]} seconds" if Chef::Config[:interval]}" +
    "\nEnable chef-client interval runs by setting `:client_fork = true` in your config file or adding `--fork` to your command line options."
  end
end
