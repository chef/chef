#
# Author:: AJ Christensen (<aj@opscode.com>)
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

require 'chef/application'
require 'chef/queue'
require 'chef/search'
require 'chef/search_index'
require 'chef/config'
require 'chef/daemon'
require 'chef/log'


class Chef::Application::Indexer < Chef::Application

  option :config_file,
    :short => "-c CONFIG",
    :long  => "--config CONFIG",
    :default => "/etc/chef/server.rb",
    :description => "The configuration file to use"

  option :log_level,
    :short        => "-l LEVEL",
    :long         => "--log_level LEVEL",
    :description  => "Set the log level (debug, info, warn, error, fatal)",
    :proc         => lambda { |l| l.to_sym }

  option :log_location,
    :short        => "-L LOGLOCATION",
    :long         => "--logfile LOGLOCATION",
    :description  => "Set the log file location, defaults to STDOUT - recommended for daemonizing",
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

  option :daemonize,
    :short => "-d",
    :long => "--daemonize",
    :description => "Daemonize the process",
    :proc => lambda { |p| true }

  def initialize
    super

    @chef_search_indexer = nil
  end

  # Create a new search indexer and connect to the stomp queues
  def setup_application
    Chef::Daemon.change_privilege

    @chef_search_indexer = Chef::SearchIndex.new
    Chef::Queue.connect
    Chef::Queue.subscribe(:queue, "index")
    Chef::Queue.subscribe(:queue, "remove")
  end

  # Run the indexer, optionally daemonizing.
  def run_application
    if Chef::Config[:daemonize]
      Chef::Daemon.daemonize("chef-indexer")
    end

    if Chef::Config[:queue_prefix]
      queue_prefix = Chef::Config[:queue_prefix]
      queue_partial_url = "/queue/#{queue_prefix}/chef"
    else
      queue_partial_url = "/queue/chef"
    end

    loop do
      object, headers = Chef::Queue.receive_msg
      Chef::Log.info("Headers #{headers.inspect}")
      if headers["destination"] == "#{queue_partial_url}/index"
        start_timer = Time.new
        @chef_search_indexer.add(object)
        @chef_search_indexer.commit
        final_timer = Time.new
        Chef::Log.info("Indexed object from #{headers['destination']} in #{final_timer - start_timer} seconds")
      elsif headers["destination"] == "#{queue_partial_url}/remove"
        start_timer = Time.new
        @chef_search_indexer.delete(object)
        @chef_search_indexer.commit
        final_timer = Time.new
        Chef::Log.info("Removed object from #{headers['destination']} in #{final_timer - start_timer} seconds")
      end
    end
  rescue SystemExit => e
    raise
  rescue Exception => e
    if Chef::Config[:interval]
      Chef::Log.error("#{e.class}")
      Chef::Log.fatal("#{e}\n#{e.backtrace.join("\n")}")
      Chef::Log.fatal("Sleeping for #{Chef::Config[:delay]} seconds before trying again")
      sleep Chef::Config[:delay]
      retry
    else
      raise
    end
  end
end
