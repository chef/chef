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
    class WindowsService < Win32::Daemon
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
        :default      => 10*60, # 10 minutes at most
        :proc         => lambda { |s| s.to_i }

      option :interval,
        :short        => "-i SECONDS",
        :long         => "--interval SECONDS",
        :description  => "Set the number of seconds to wait between chef-client runs",
        :default      => 30*60, # 30 minutes"
        :proc         => lambda { |s| s.to_i }

      def service_init
        reconfigure
        Chef::Log.info("Chef Client Service initialized")
      end

      def service_main(*startup_parameters)

        # Sleep for at most this many seconds before checking the state of the service
        # Tweak this to be more or less responsive (and see 'sleep_fitfully' below)
        nap_length = 10

        while running?
          if state == RUNNING

            begin

              # Reconfigure each time through to pick up any changes in the client file
              Chef::Log.info("Reconfiguring with startup parameters")
              reconfigure(startup_parameters)

              # Avoid the "thundering herd" problem
              splay_length = rand Chef::Config[:splay]
              Chef::Log.info("Splay sleep for #{splay_length} seconds")
              sleep_fitfully(splay_length, nap_length)

              # If we've stopped, then bail out now, instead of going on to run Chef
              next if state != RUNNING

              @chef_client = Chef::Client.new()
              @chef_client_json = nil

              @chef_client.run
              @chef_client = nil

              Chef::Log.info("Sleeping between Chef runs for #{Chef::Config[:interval]} seconds")
              sleep_fitfully(Chef::Config[:interval], nap_length)

            rescue SystemExit => e
              raise

            rescue Exception => e
              Chef::Log.error("#{e.class}: #{e}")
              Chef::Application.debug_stacktrace(e)
              Chef::Log.error("Sleeping for #{Chef::Config[:interval]} seconds before trying again")

              sleep_fitfully(Chef::Config[:interval], nap_length)

              retry
            ensure
              GC.start
            end

          else # PAUSED or IDLE
            sleep 5
          end
        end

        # We've left the loop, the daemon is about to exit.
        Chef::Log.info("Chef Client Service shutting down")

      end

      ################################################################################
      # Control Signal Callback Methods
      ################################################################################

      def service_stop
        Chef::Log.info("SERVICE_CONTROL_STOP received, stopping")
        puts "This is on standard output"
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

      # Lifted from Chef::Application, with addition of optional startup parameters
      # for playing nicely with Windows Services
      def reconfigure(startup_parameters=[])
        configure_chef startup_parameters
        configure_logging

        Chef::Config[:chef_server_url] = config[:chef_server_url] if config.has_key? :chef_server_url
        unless Chef::Config[:exception_handlers].any? {|h| Chef::Handler::ErrorReport === h}
          Chef::Config[:exception_handlers] << Chef::Handler::ErrorReport.new
        end

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
        Chef::Config.merge!(config)

        # Merge in the configuration from an external file
        configuration_file = config[:config_file]

        begin
          case configuration_file
          when /^(http|https):\/\//
            Chef::Log.info("Fetching remote configuration file: #{configuration_file}")
            Chef::REST.new("", nil, nil).fetch(configuration_file) { |f| apply_config(f.path) }
          else
            # In Chef::Application, the block calls a private method 'apply_config'
            # It made some assumptions about the priority of configuration parameters from
            # various sources that aren't applicable in a Windows Service, so we're just
            # merging in the config file parameters here.  Everything else is handled
            # in the rest of this 'configure_chef' method.
            ::File::open(configuration_file) { |f| Chef::Config.from_file(f.path) }
          end

        rescue SocketError => error
          Chef::Application.fatal!("Error getting config file #{configuration_file}", 2)

        rescue Exception => error
          Chef::Log.warn("*****************************************")
          Chef::Log.warn("Can not find config file: #{configuration_file}, using defaults.")
          Chef::Log.warn("#{error.message}")
          Chef::Log.warn("*****************************************")

          Chef::Config.merge!(config)
        end


      end

      # Since we need to be able to respond to signals between Chef runs, we need to periodically
      # wake up to see if we're still in the running state.  The method returns when it has slept
      # for +total_sleep_duration+ seconds (but at least +nap_length+ seconds), or when the service
      # is no longer in the +RUNNING+ state, whichever comes first.
      def sleep_fitfully(total_sleep_duration, nap_length)
        naps = [1, total_sleep_duration / nap_length].max # always take at least 1 nap
        (1..naps).each do
          return unless state == RUNNING
          sleep nap_length
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
