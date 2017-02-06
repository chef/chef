#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright 2011-2016, Chef Software, Inc.
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
#

if RUBY_PLATFORM =~ /mswin|mingw32|windows/
  require "win32/service"
end
require "chef/config"
require "mixlib/cli"

class Chef
  class Application
    #
    # This class is used to create and manage a windows service.
    # Service should be created using Daemon class from
    # win32/service gem.
    # For an example see: Chef::Application::WindowsService
    #
    # Outside programs are expected to use this class to manage
    # windows services.
    #
    class WindowsServiceManager
      include Mixlib::CLI

      option :action,
        :short => "-a ACTION",
        :long  => "--action ACTION",
        :default => "status",
        :description => "Action to carry out on chef-service (install, uninstall, status, start, stop, pause, or resume)"

      option :config_file,
        :short => "-c CONFIG",
        :long  => "--config CONFIG",
        :default => "#{ENV['SYSTEMDRIVE']}/chef/client.rb",
        :description => "The configuration file to use for chef runs"

      option :log_location,
        :short        => "-L LOGLOCATION",
        :long         => "--logfile LOGLOCATION",
        :description  => "Set the log file location for chef-service"

      option :help,
        :short        => "-h",
        :long         => "--help",
        :description  => "Show this message",
        :on           => :tail,
        :boolean      => true,
        :show_options => true,
        :exit         => 0

      option :version,
        :short        => "-v",
        :long         => "--version",
        :description  => "Show chef version",
        :boolean      => true,
        :proc         => lambda { |v| puts "Chef: #{::Chef::VERSION}" },
        :exit         => 0

      def initialize(service_options)
        # having to call super in initialize is the most annoying
        # anti-pattern :(
        super()

        raise ArgumentError, "Service definition is not provided" if service_options.nil?

        required_options = [:service_name, :service_display_name, :service_description, :service_file_path]

        required_options.each do |req_option|
          if !service_options.has_key?(req_option)
            raise ArgumentError, "Service definition doesn't contain required option #{req_option}"
          end
        end

        @service_name = service_options[:service_name]
        @service_display_name = service_options[:service_display_name]
        @service_description = service_options[:service_description]
        @service_file_path = service_options[:service_file_path]
        @service_start_name = service_options[:run_as_user]
        @password = service_options[:run_as_password]
        @delayed_start = service_options[:delayed_start]
        @dependencies = service_options[:dependencies]
      end

      def run(params = ARGV)
        parse_options(params)

        case config[:action]
        when "install"
          if service_exists?
            puts "Service #{@service_name} already exists on the system."
          else
            ruby = File.join(RbConfig::CONFIG["bindir"], "ruby")

            opts = ""
            opts << " -c #{config[:config_file]}" if config[:config_file]
            opts << " -L #{config[:log_location]}" if config[:log_location]

            # Quote the full paths to deal with possible spaces in the path name.
            # Also ensure all forward slashes are backslashes
            cmd = "\"#{ruby}\" \"#{@service_file_path}\" #{opts}".gsub(File::SEPARATOR, File::ALT_SEPARATOR)

            ::Win32::Service.new(
              :service_name       => @service_name,
              :display_name       => @service_display_name,
              :description        => @service_description,
              # Prior to 0.8.5, win32-service creates interactive services by default,
              # and we don't want that, so we need to override the service type.
              :service_type       => ::Win32::Service::SERVICE_WIN32_OWN_PROCESS,
              :start_type         => ::Win32::Service::SERVICE_AUTO_START,
              :binary_path_name   => cmd,
              :service_start_name => @service_start_name,
              :password           => @password,
              :dependencies       => @dependencies
            )
            unless @delayed_start.nil?
              ::Win32::Service.configure(
                :service_name     => @service_name,
                :delayed_start    => @delayed_start
              )
            end
            puts "Service '#{@service_name}' has successfully been installed."
          end
        when "status"
          if !service_exists?
            puts "Service #{@service_name} doesn't exist on the system."
          else
            puts "State of #{@service_name} service is: #{current_state}"
          end
        when "start"
          # TODO: allow override of startup parameters here?
          take_action("start", RUNNING)
        when "stop"
          take_action("stop", STOPPED)
        when "uninstall", "delete"
          take_action("stop", STOPPED)
          unless service_exists?
            puts "Service #{@service_name} doesn't exist on the system."
          else
            ::Win32::Service.delete(@service_name)
            puts "Service #{@service_name} deleted"
          end
        when "pause"
          take_action("pause", PAUSED)
        when "resume"
          take_action("resume", RUNNING)
        end
      end

      private

      # Just some state constants
      STOPPED = "stopped"
      RUNNING = "running"
      PAUSED = "paused"

      def service_exists?
        return ::Win32::Service.exists?(@service_name)
      end

      def take_action(action = nil, desired_state = nil)
        if service_exists?
          if current_state != desired_state
            ::Win32::Service.send(action, @service_name)
            wait_for_state(desired_state)
            puts "Service '#{@service_name}' is now '#{current_state}'."
          else
            puts "Service '#{@service_name}' is already '#{desired_state}'."
          end
        else
          puts "Cannot '#{action}' service '#{@service_name}'"
          puts "Service #{@service_name} doesn't exist on the system."
        end
      end

      def current_state
        ::Win32::Service.status(@service_name).current_state
      end

      # Helper method that waits for a status to change its state since state
      # changes aren't usually instantaneous.
      def wait_for_state(desired_state)
        while current_state != desired_state
          puts "One moment... #{current_state}"
          sleep 1
        end
      end

    end
  end
end
