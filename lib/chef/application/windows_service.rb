#
# Author:: Christopher Maier (<maier@lambda.local>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef'
require 'chef/application'
require 'chef/client'
require 'chef/config'
require 'chef/handler/error_report'
require 'chef/log'
require 'chef/rest'
require 'mixlib/cli'
require 'socket'
require 'win32/daemon'

class Chef
  class Application
    class WindowsService < ::Win32::Daemon
      include Mixlib::CLI

      option :config_file,
        :short => "-c CONFIG",
        :long => "--config CONFIG",
        :default => "#{ENV['SYSTEMDRIVE']}/chef/client.rb",
        :description => ""

      option :log_location,
        :short        => "-L LOGLOCATION",
        :long         => "--logfile LOGLOCATION",
        :description  => "Set the log file location",
        :default => "#{ENV['SYSTEMDRIVE']}/chef/client.log"

      option :splay,
        :short        => "-s SECONDS",
        :long         => "--splay SECONDS",
        :description  => "The splay time for running at intervals, in seconds",
        :proc         => lambda { |s| s.to_i }

      option :interval,
        :short        => "-i SECONDS",
        :long         => "--interval SECONDS",
        :description  => "Set the number of seconds to wait between chef-client runs",
        :proc         => lambda { |s| s.to_i }

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

      def service_init
        reconfigure
        Chef::Log.info("Chef Client Service initialized")
      end

      def service_main(*startup_parameters)

        while running?
          if state == RUNNING
            begin
              # Reconfigure each time through to pick up any changes in the client file
              Chef::Log.info("Reconfiguring with startup parameters")
              reconfigure(startup_parameters)

              splay = rand Chef::Config[:splay]
              Chef::Log.debug("Splay sleep #{splay} seconds")
              sleep splay

              # If we've stopped, then bail out now, instead of going on to run Chef
              next if state != RUNNING

              run_chef_client

              Chef::Log.debug("Sleeping for #{Chef::Config[:interval]} seconds")
              client_sleep Chef::Config[:interval]
            rescue Chef::Application::Wakeup => e
              Chef::Log.debug("Received Wakeup signal.  Starting run.")
              next
            rescue SystemExit => e
              raise
            rescue Exception => e
              Chef::Log.error("#{e.class}: #{e}")
              Chef::Application.debug_stacktrace(e)
              Chef::Log.error("Sleeping for #{Chef::Config[:interval]} seconds before trying again")
              client_sleep Chef::Config[:interval]
              retry
            end
          else # PAUSED or IDLE
            sleep 5
          end
        end
      end

      ################################################################################
      # Control Signal Callback Methods
      ################################################################################

      def service_stop
        Chef::Log.info("SERVICE_CONTROL_STOP received, stopping")
      end

      def service_pause
        Chef::Log.info("SERVICE_CONTROL_PAUSE received, pausing")
      end

      def service_resume
        Chef::Log.info("SERVICE_CONTROL_CONTINUE received, resuming")
      end

      def service_shutdown
        Chef::Log.info("SERVICE_CONTROL_SHUTDOWN received, shutting down")
      end

      ################################################################################
      # Internal Methods
      ################################################################################

      private

      def apply_config(config_file_path)
        Chef::Config.from_file(config_file_path)
        Chef::Config.merge!(config)
      end

      # Lifted from Chef::Application, with addition of optional startup parameters
      # for playing nicely with Windows Services
      def reconfigure(startup_parameters=[])
        configure_chef startup_parameters
        configure_logging

        Chef::Config[:chef_server_url] = config[:chef_server_url] if config.has_key? :chef_server_url
        unless Chef::Config[:exception_handlers].any? {|h| Chef::Handler::ErrorReport === h}
          Chef::Config[:exception_handlers] << Chef::Handler::ErrorReport.new
        end

        Chef::Config[:interval] ||= 1800
      end

      # Lifted from Chef::Application and Chef::Application::Client
      # MUST BE RUN AFTER configuration has been parsed!
      def configure_logging
        # Implementation from Chef::Application
        Chef::Log.init(Chef::Config[:log_location])
        Chef::Log.level = Chef::Config[:log_level]

        # Implementation from Chef::Application::Client
        Mixlib::Authentication::Log.use_log_devices( Chef::Log )
        Ohai::Log.use_log_devices( Chef::Log )
      end

      def configure_chef(startup_parameters)
        # Bit of a hack ahead:
        # It is possible to specify a service's binary_path_name with arguments, like "foo.exe -x argX".
        # It is also possible to specify startup parameters separately, either via the the Services manager
        # or by using the registry (I think).

        # In order to accommodate all possible sources of parameterization, we first parse any command line
        # arguments.  We then parse any startup parameters.  This works, because Mixlib::CLI reuses its internal
        # 'config' hash; thus, anything in startup parameters will override any command line parameters that
        # might be set via the service's binary_path_name
        #
        # All these parameters then get layered on top of those from Chef::Config

        parse_options # Operates on ARGV by default
        parse_options startup_parameters

        begin
          case config[:config_file]
          when /^(http|https):\/\//
            Chef::REST.new("", nil, nil).fetch(config[:config_file]) { |f| apply_config(f.path) }
          else
            ::File::open(config[:config_file]) { |f| apply_config(f.path) }
          end
        rescue Errno::ENOENT => error
          Chef::Log.warn("*****************************************")
          Chef::Log.warn("Did not find config file: #{config[:config_file]}, using command line options.")
          Chef::Log.warn("*****************************************")

          Chef::Config.merge!(config)
        rescue SocketError => error
          Chef::Application.fatal!("Error getting config file #{Chef::Config[:config_file]}", 2)
        rescue Chef::Exceptions::ConfigurationError => error
          Chef::Application.fatal!("Error processing config file #{Chef::Config[:config_file]} with error #{error.message}", 2)
        rescue Exception => error
          Chef::Application.fatal!("Unknown error processing config file #{Chef::Config[:config_file]} with error #{error.message}", 2)
        end
      end

      # Since we need to be able to respond to signals between Chef runs, we need to periodically
      # wake up to see if we're still in the running state.  The method returns when it has slept
      # for +sec+ seconds (but at least +10+ seconds), or when the service
      # is no client_sleep in the +RUNNING+ state, whichever comes first.
      def client_sleep(sec)
        chunk_length = 10
        chunks = sec / chunk_length
        chunks = 1 if chunks < 1
        (1..chunks).each do
          return unless state == RUNNING
          sleep chunk_length
        end
      end
      
    end
  end
end

# To run this file as a service, it must be called as a script from within
# the Windows Service framework.  In that case, kick off the main loop!
if __FILE__ == $0
    Chef::Application::WindowsService.mainloop
end
