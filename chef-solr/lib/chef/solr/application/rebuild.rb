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
require 'nanite'
require 'eventmachine'

class Chef
  class Solr
    class Application
      class Rebuild < Chef::Application
  
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

        option :couchdb_database,
          :short => "-d DB",
          :long => "--couchdb-database DB",
          :description => "The CouchDB Database to re-index"

        option :couchdb_url,
          :short => "-u URL",
          :long => "--couchdb-url URL",
          :description => "The CouchDB URL"

        def initialize
          super

          @index = Chef::Solr::Index.new
          ::Nanite::Log.logger = Chef::Log.logger
        end

        def setup_application
          Chef::Log.level = Chef::Config[:log_level]
          Chef::Log.warn("This operation is destructive!")
          Chef::Log.warn("I'm going to count to 20, and then delete your Solr index and rebuild it.")
          Chef::Log.warn("CTRL-C will, of course, stop this disaster.")
          Chef::Nanite.in_event { }
          0.upto(20) do |num|
            Chef::Log.warn("... #{num}")
            sleep 1
          end
          Chef::Log.warn("... Bombs away!")
        end

        def run_application
          s = Chef::Solr.new(Chef::Config[:solr_url])
          Chef::Log.info("Destroying the index")
          s.rebuild_index
        end
      end
    end
  end
end
