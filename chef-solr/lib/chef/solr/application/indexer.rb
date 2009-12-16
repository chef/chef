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
require 'chef/solr/index_actor'
require 'chef/daemon'
require 'chef/nanite'
require 'chef/webui_user'
require 'nanite'
require 'eventmachine'

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

        option :nanite_identity,
          :long => "--nanite-identity ID",
          :description => "The nanite identity"

        option :nanite_host,
          :long => "--nanite-host HOST",
          :description => "The nanite host"

        option :nanite_port,
          :long => "--nanite-port PORT",
          :description => "The nanite port"

        option :nanite_user,
          :long => "--nanite-user USER",
          :description => "The nanite user"

        option :nanite_pass,
          :long => "--nanite-pass PASS",
          :description => "The nanite password"

        option :nanite_vhost,
          :long => "--nanite-vhost VHOST",
          :description => "The nanite vhost"

        def initialize
          super

          @index = Chef::Solr::Index.new
          ::Nanite::Log.logger = Chef::Log.logger
        end

        def setup_application
          Chef::Daemon.change_privilege
          identity = Chef::Config[:nanite_identity] ? Chef::Config[:nanite_identity] : Chef::Nanite.get_identity("solr-indexer")
          @nanite_config = { 
            :host => Chef::Config[:nanite_host],
            :port => 5672,
            :user => Chef::Config[:nanite_user],
            :pass => Chef::Config[:nanite_pass],
            :vhost => Chef::Config[:nanite_vhost],
            :identity => identity, 
            :format => :json
          }
          Chef::Log.level = Chef::Config[:log_level]
        end

        def run_application
          if Chef::Config[:daemonize]
            Chef::Daemon.daemonize("chef-solr-indexer")
          end

          EM.run do
            agent = ::Nanite::Agent.start(@nanite_config)
            agent.register(Chef::Solr::IndexActor.new, 'index')
            agent.send :advertise_services
          end
        end
      end
    end
  end
end
