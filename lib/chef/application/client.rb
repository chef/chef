#
# Author:: AJ Christensen (<aj@chef.io)
# Author:: Christopher Brown (<cb@chef.io>)
# Author:: Mark Mzyk (mmzyk@chef.io)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "base"
require_relative "../handler/error_report"
require_relative "../workstation_config_loader"
autoload :URI, "uri"
require "chef-utils" unless defined?(ChefUtils::CANARY)
module Mixlib
  module Authentication
    autoload :Log, "mixlib/authentication"
  end
end
autoload :Train, "train"

# DO NOT MAKE EDITS, see Chef::Application::Base
#
# External code may call / subclass or make references to this class.
#
class Chef::Application::Client < Chef::Application::Base

  option :config_file,
    short: "-c CONFIG",
    long: "--config CONFIG",
    description: "The configuration file to use."

  option :credentials,
    long: "--credentials CREDENTIALS",
    description: "Credentials file to use. Default: ~/.chef/credentials"

  unless ChefUtils.windows?
    option :daemonize,
      short: "-d [WAIT]",
      long: "--daemonize [WAIT]",
      description: "Daemonize the process. Accepts an optional integer which is the " \
        "number of seconds to wait before the first daemonized run.",
      proc: lambda { |wait| /^\d+$/.match?(wait) ? wait.to_i : true }
  end

  option :pid_file,
    short: "-P PID_FILE",
    long: "--pid PIDFILE",
    description: "Set the PID file location, for the #{ChefUtils::Dist::Infra::CLIENT} daemon process. Defaults to /tmp/chef-client.pid.",
    proc: nil

  option :runlist,
    short: "-r RunlistItem,RunlistItem...",
    long: "--runlist RunlistItem,RunlistItem...",
    description: "Permanently replace current run list with specified items.",
    proc: lambda { |items|
      items = items.split(",")
      items.compact.map do |item|
        Chef::RunList::RunListItem.new(item)
      end
    }

  option :recipe_url,
    long: "--recipe-url=RECIPE_URL",
    description: "Pull down a remote archive of recipes and unpack it to the cookbook cache. Only used in local mode."

  # Reconfigure the chef client
  # Re-open the JSON attributes and load them into the node
  def reconfigure
    super

    raise Chef::Exceptions::PIDFileLockfileMatch if Chef::Util::PathHelper.paths_eql? (Chef::Config[:pid_file] || "" ), (Chef::Config[:lockfile] || "")

    set_specific_recipes

    Chef::Config[:fips] = config[:fips] if config.key? :fips

    Chef::Config[:chef_server_url] = config[:chef_server_url] if config.key? :chef_server_url

    Chef::Config.local_mode = config[:local_mode] if config.key?(:local_mode)

    if Chef::Config.key?(:chef_repo_path) && Chef::Config.chef_repo_path.nil?
      Chef::Config.delete(:chef_repo_path)
      Chef::Log.warn "chef_repo_path was set in a config file but was empty. Assuming #{Chef::Config.chef_repo_path}"
    end

    if Chef::Config.local_mode && !Chef::Config.key?(:cookbook_path) && !Chef::Config.key?(:chef_repo_path)
      Chef::Config.chef_repo_path = Chef::Config.find_chef_repo_path(Dir.pwd)
    end

    if Chef::Config[:recipe_url]
      if !Chef::Config.local_mode
        Chef::Application.fatal!("recipe-url can be used only in local-mode")
      else
        if Chef::Config[:delete_entire_chef_repo]
          Chef::Log.trace "Cleanup path #{Chef::Config.chef_repo_path} before extract recipes into it"
          FileUtils.rm_rf(Chef::Config.chef_repo_path, secure: true)
        end
        Chef::Log.trace "Creating path #{Chef::Config.chef_repo_path} to extract recipes into"
        FileUtils.mkdir_p(Chef::Config.chef_repo_path)
        tarball_path = File.join(Chef::Config.chef_repo_path, "recipes.tgz")
        fetch_recipe_tarball(Chef::Config[:recipe_url], tarball_path)
        Mixlib::Archive.new(tarball_path).extract(Chef::Config.chef_repo_path, perms: false, ignore: /^\.$/)
        config_path = File.join(Chef::Config.chef_repo_path, "#{ChefUtils::Dist::Infra::USER_CONF_DIR}/config.rb")
        Chef::Config.from_string(IO.read(config_path), config_path) if File.file?(config_path)
      end
    end

    Chef::Config.chef_zero.host = config[:chef_zero_host] if config[:chef_zero_host]
    Chef::Config.chef_zero.port = config[:chef_zero_port] if config[:chef_zero_port]

    if config[:target] || Chef::Config.target
      require "ed25519" # required for net-ssh to support ed25519 keys

      Chef::Config.target_mode.host = config[:target] || Chef::Config.target
      if URI.parse(Chef::Config.target_mode.host).scheme
        train_config = Train.unpack_target_from_uri(Chef::Config.target_mode.host)
        Chef::Config.target_mode = train_config
      end
      Chef::Config.target_mode.enabled = true
      Chef::Config.node_name = Chef::Config.target_mode.host unless Chef::Config.node_name
    end

    if config[:credentials]
      unless File.exist?(config[:credentials])
        Chef::Application.fatal!("credentials file #{config[:credentials]} not found")
      end

      Chef::Config.credentials = config[:credentials]
    end

    if Chef::Config[:daemonize]
      Chef::Config[:interval] ||= 1800
    end

    if Chef::Config[:once]
      Chef::Config[:interval] = nil
      Chef::Config[:splay] = nil
    end

    # supervisor processes are enabled by default for interval-running processes but not for one-shot runs
    if Chef::Config[:client_fork].nil?
      Chef::Config[:client_fork] = !!Chef::Config[:interval]
    end

    if Chef::Config[:interval]
      if Chef::Platform.windows?
        Chef::Application.fatal!(windows_interval_error_message)
      elsif !Chef::Config[:client_fork]
        Chef::Application.fatal!(unforked_interval_error_message)
      end
    end

    if Chef::Config[:json_attribs]
      config_fetcher = Chef::ConfigFetcher.new(Chef::Config[:json_attribs])
      @chef_client_json = config_fetcher.fetch_json
    end
  end

  def load_config_file
    if !config.key?(:config_file) && !config[:disable_config]
      if config[:local_mode]
        config[:config_file] = Chef::WorkstationConfigLoader.new(nil, Chef::Log).config_location
      else
        config[:config_file] = Chef::Config.platform_specific_path("#{ChefConfig::Config.etc_chef_dir}/client.rb")
      end
    end

    # Load the client.rb configuration
    super

    # Load all config files in client.d
    load_dot_d(Chef::Config[:client_d_dir]) if Chef::Config[:client_d_dir]
  end

  def configure_logging
    super
    Mixlib::Authentication::Log.use_log_devices( Chef::Log )
    Ohai::Log.use_log_devices( Chef::Log )
  end

end
