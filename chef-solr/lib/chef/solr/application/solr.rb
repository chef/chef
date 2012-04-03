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


require 'rexml/document'
require 'chef/log'
require 'chef/config'
require 'chef/application'
require 'chef/daemon'
require 'chef/solr'

class Chef
  class Solr
    class Application
      class Solr < Chef::Application

        attr_accessor :logfile

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

        option :pid_file,
          :short        => "-P PID_FILE",
          :long         => "--pid PIDFILE",
          :description  => "Set the PID file location, defaults to /tmp/chef-solr.pid",
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

        option :version,
          :short => "-v",
          :long => "--version",
          :description => "Show chef-solr version",
          :boolean => true,
          :proc => lambda {|v| puts "chef-solr: #{::Chef::Solr::VERSION}"},
          :exit => 0

        def initialize
          super
        end

        def schema_file_path
          @schema_file_path ||= File.join(Chef::Config[:solr_home_path], 'conf', 'schema.xml')
        end

        def solr_config_file_path
          @solr_config_file_path ||= File.join(Chef::Config[:solr_home_path], 'conf', 'solrconfig.xml')
        end

        def schema_document
          @schema_document ||= begin
            File.open(schema_file_path, 'r') do |xmlsux|
              REXML::Document.new(xmlsux)
            end
          end
        end

        def config_document
          @config_document ||=begin
            File.open(solr_config_file_path, 'r') do |xmlsux|
              REXML::Document.new(xmlsux)
            end
          end
        end

        def schema_attributes
          @schema_attributes ||= REXML::XPath.first(schema_document, '/schema').attributes
        end

        def solr_main_index_elements
          location = '/config/mainIndex/'
          @solr_main_index_elements ||= REXML::XPath.first(config_document, location).elements
        end

        def solr_schema_name
          schema_attributes["name"]
        end

        def solr_schema_version
          schema_attributes["version"]
        end

        def solr_main_index_max_field_length
          @solr_main_index_max_field_length ||=begin
            field_length_el = solr_main_index_elements.select do |el|
              el.name == 'maxFieldLength'
            end

            field_length_el.empty? ? nil : field_length_el.first.text.to_i
          end
        end

        def valid_schema_name?
          solr_schema_name == Chef::Solr::SCHEMA_NAME
        end

        def valid_schema_version?
          solr_schema_version == Chef::Solr::SCHEMA_VERSION
        end

        def check_value_of_main_index_max_field_length
          if solr_main_index_max_field_length
            unless solr_main_index_max_field_length > 10000
              message  = "The maxFieldLimit for the mainIndex is set to #{solr_main_index_max_field_length}.  "
              message << "It's recommended to increase this value (in #{solr_config_file_path})."
              Chef::Log.warn message
            end
          else
            Chef::Log.warn "Unable to determine the maxFieldLimit for the mainIndex (in #{solr_config_file_path})"
          end
        end

        def solr_home_exist?
          File.directory?(Chef::Config[:solr_home_path])
        end

        def solr_data_dir_exist?
          File.directory?(Chef::Config[:solr_data_path])
        end

        def solr_jetty_home_exist?
          File.directory?(Chef::Config[:solr_jetty_path])
        end

        def assert_solr_installed!
          unless solr_home_exist? && solr_data_dir_exist? && solr_jetty_home_exist?
            Chef::Log.fatal "Chef Solr is not installed or solr_home_path, solr_data_path, and solr_jetty_path are misconfigured."
            Chef::Log.fatal "Your current configuration is:"
            Chef::Log.fatal "solr_home_path:  #{Chef::Config[:solr_home_path]}"
            Chef::Log.fatal "solr_data_path:  #{Chef::Config[:solr_data_path]}"
            Chef::Log.fatal "solr_jetty_path: #{Chef::Config[:solr_jetty_path]}"
            Chef::Log.fatal "You can install Chef Solr using the chef-solr-installer script."
            exit 1
          end
        end

        def assert_valid_schema!
          unless valid_schema_name? && valid_schema_version?
            Chef::Log.fatal "Your Chef Solr installation needs to be upgraded."
            Chef::Log.fatal "Expected schema version #{Chef::Solr::SCHEMA_VERSION} but version #{solr_schema_version} is installed."
            Chef::Log.fatal "Use chef-solr-installer to upgrade your Solr install after backing up your data."
            exit 1
          end
        end

        def setup_application
          assert_solr_installed!
          assert_valid_schema!
          check_value_of_main_index_max_field_length

          # Need to redirect stdout and stderr so Java process inherits them.
          # If -L wasn't specified, Chef::Config[:log_location] will be an IO
          # object, otherwise it will be a String.
          #
          # Open this as a privileged user and hang onto it
          if Chef::Config[:log_location].kind_of?(String)
            @logfile = File.new(Chef::Config[:log_location], "a")
          end

          Chef::Log.level = Chef::Config[:log_level]

          Chef::Daemon.change_privilege
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

            # Opened earlier before we dropped privileges, don't need it anymore
            close_and_reopen_log_file if @logfile

            Kernel.exec(command)

          end
        end

        def close_and_reopen_log_file
          Chef::Log.close

          STDOUT.reopen(@logfile)
          STDERR.reopen(@logfile)
        end

      end
    end
  end
end
