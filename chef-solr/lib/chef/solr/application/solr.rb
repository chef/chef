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
require 'chef/daemon'
require 'chef/client'

class Chef
  class Solr
    class Application
      class Solr < Chef::Application
  
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

        option :solr_jetty_path,
          :short => "-W PATH",
          :long => "--solr-jetty-dir PATH",
          :description => "Where to place the Solr Jetty instance"

        option :solr_data_path,
          :short => "-D PATH",
          :long => "--solr-data-dir PATH",
          :description => "Where the Solr data lives"

        option :solr_home_path,
          :short => "-H PATH",
          :long => "--solr-home-dir PATH",
          :description => "Solr home directory"

        option :solr_heap_size,
          :short => "-x SIZE",
          :long => "--solor-heap-size SIZE",
          :description => "Set the size of the Java Heap"

        option :solr_java_opts,
          :short => "-j OPTS",
          :long => "--java-opts OPTS",
          :description => "Raw options passed to Java" 

        def initialize
          super
          Chef::Log.level = Chef::Config[:log_level] 
        end

        def setup_application
          Chef::Daemon.change_privilege

          # Build up a client
          c = Chef::Client.new
          c.build_node(nil, true)

          solr_base = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "..", "solr"))

          # Create the Jetty container
          unless File.directory?(Chef::Config[:solr_jetty_path])
            Chef::Log.warn("Initializing the Jetty container") 
            solr_jetty_dir = Chef::Resource::Directory.new(Chef::Config[:solr_jetty_path], nil, c.node)
            solr_jetty_dir.recursive(true)
            solr_jetty_dir.run_action(:create)
            solr_jetty_untar = Chef::Resource::Execute.new("untar_jetty", nil, c.node)
            solr_jetty_untar.command("tar zxvf #{File.join(solr_base, 'solr-jetty.tar.gz')}")
            solr_jetty_untar.cwd(Chef::Config[:solr_jetty_path])
            solr_jetty_untar.run_action(:run)
          end

          # Create the solr home
          unless File.directory?(Chef::Config[:solr_home_path])
            Chef::Log.warn("Initializing Solr home directory") 
            solr_home_dir = Chef::Resource::Directory.new(Chef::Config[:solr_home_path], nil, c.node)
            solr_home_dir.recursive(true)
            solr_home_dir.run_action(:create)
            solr_jetty_untar = Chef::Resource::Execute.new("untar_solr_home", nil, c.node)
            solr_jetty_untar.command("tar zxvf #{File.join(solr_base, 'solr-home.tar.gz')}")
            solr_jetty_untar.cwd(Chef::Config[:solr_home_path])
            solr_jetty_untar.run_action(:run)
          end

          # Create the solr data path 
          unless File.directory?(Chef::Config[:solr_data_path])
            Chef::Log.warn("Initializing Solr data directory")
            solr_data_dir = Chef::Resource::Directory.new(Chef::Config[:solr_data_path], nil, c.node)
            solr_data_dir.recursive(true)
            solr_data_dir.run_action(:create)
          end
        end

        def run_application
          if Chef::Config[:daemonize]
            Chef::Daemon.daemonize("chef-solr")
          end
          Dir.chdir(Chef::Config[:solr_jetty_path]) do
            command = "java -Xmx#{Chef::Config[:solr_heap_size]} -Xms#{Chef::Config[:solr_heap_size]}"
            command << " -Dsolr.data.dir=#{Chef::Config[:solr_data_path]}"
            command << " -Dsolr.solr.home=#{Chef::Config[:solr_home_path]}"
            command << " #{Chef::Config[:solr_java_opts]}" if Chef::Config[:solr_java_opts]
            command << " -jar #{File.join(Chef::Config[:solr_jetty_path], 'start.jar')}"
            Chef::Log.info("Starting Solr with #{command}")
            Kernel.exec(command)

          end
        end
      end
    end
  end
end
