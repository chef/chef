#
# Author:: AJ Christensen (<aj@opscode.com)
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
require 'chef/log'
require 'chef/config'
require 'chef/application'
require 'chef/solr'
require 'chef/solr/index'
require 'chef/solr/index_queue_consumer'
require 'chef/daemon'
require 'chef/webui_user'

class Chef
  class Solr
    class Application
      class Indexer < Chef::Application
  
        option :config_file, 
          :short => "-c CONFIG",
          :long  => "--config CONFIG",
          :default => "/etc/chef/solr.rb",
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

        option :amqp_host,
          :long => "--amqp-host HOST",
          :description => "The amqp host"

        option :amqp_port,
          :long => "--amqp-port PORT",
          :description => "The amqp port"

        option :amqp_user,
          :long => "--amqp-user USER",
          :description => "The amqp user"

        option :amqp_pass,
          :long => "--amqp-pass PASS",
          :description => "The amqp password"

        option :amqp_vhost,
          :long => "--amqp-vhost VHOST",
          :description => "The amqp vhost"
        
        Signal.trap("INT") do
          begin
            AmqpClient.instance.stop
          rescue Bunny::ProtocolError, Bunny::ConnectionError, Bunny::UnsubscribeError
          end
          fatal!("SIGINT received, stopping", 2)
        end
        
        Kernel.trap("TERM") do 
          begin
            AmqpClient.instance.stop
          rescue Bunny::ProtocolError, Bunny::ConnectionError, Bunny::UnsubscribeError
          end
          fatal!("SIGTERM received, stopping", 1)
        end
        
        def initialize
          super

          @index = Chef::Solr::Index.new
          @consumer = Chef::Solr::IndexQueueConsumer.new
        end

        def setup_application
          Chef::Daemon.change_privilege
          Chef::Log.level = Chef::Config[:log_level]
        end

        def run_application
          Chef::Daemon.daemonize("chef-solr-indexer") if Chef::Config[:daemonize]
          @consumer.start
        end
      end
    end
  end
end
