#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'win32/service'
require 'chef/config'
require 'mixlib/cli'

class Chef
  class Application
    class WindowsServiceManager
      include Mixlib::CLI

      option :action,
        :short => "-a ACTION",
        :long  => "--action ACTION",
        :default => "start",
        :description => "Action to carry out on chef-service (install, uninstall, status, start, stop, pause, or resume)"

      option :config_file,
        :short => "-c CONFIG",
        :long  => "--config CONFIG",
        :default => "#{ENV['SYSTEMDRIVE']}/chef/client.rb",
        :description => "The configuration file to use for chef runs"

      option :log_location,
        :short        => "-L LOGLOCATION",
        :long         => "--logfile LOGLOCATION",
        :description  => "Set the log file location for chef-service",
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

      option :help,
        :short        => "-h",
        :long         => "--help",
        :description  => "Show this message",
        :on           => :tail,
        :boolean      => true,
        :show_options => true,
        :exit         => 0

      CHEF_SERVICE_NAME = "chef-client"
      CHEF_SERVICE_DISPLAY_NAME = "Chef-Client Service"
      CHEF_SERVICE_DESCRIPTION = "Runs chef-client periodically"
      
      def run
        parse_options

        case config[:action]
        when 'install'
          if service_exists?
            puts "Service #{CHEF_SERVICE_NAME} already exists on the system."
          else
            ruby = File.join(RbConfig::CONFIG['bindir'], 'ruby')
            path = File.expand_path(File.join(File.dirname(__FILE__), 'windows_service.rb'))
            
            opts = ""
            opts << " -c #{config[:config_file]}" if config[:config_file]
            opts << " -L #{config[:log_location]}" if config[:log_location]
            opts << " -i #{config[:interval]}" if config[:interval]
            opts << " -s #{config[:splay]}" if config[:splay]
            
            # Quote the full paths to deal with possible spaces in the path name.
            # Also ensure all forward slashes are backslashes
            cmd = "\"#{ruby}\" \"#{path}\" #{opts}".gsub(File::SEPARATOR, File::ALT_SEPARATOR)
            
            ::Win32::Service.new(
                                 :service_name     => CHEF_SERVICE_NAME,
                                 :display_name     => CHEF_SERVICE_DISPLAY_NAME,
                                 :description      => CHEF_SERVICE_DESCRIPTION,
                                 :start_type       => ::Win32::Service::SERVICE_AUTO_START,
                                 :binary_path_name => cmd)
            puts "Service '#{CHEF_SERVICE_NAME}' has successfully been installed."
          end
        when 'status'
          if !service_exists?
            puts "Service #{CHEF_SERVICE_NAME} doesn't exist on the system."
          else
            puts "State of #{CHEF_SERVICE_NAME} service is: #{current_state}"
          end
        when 'start'
          # TODO: allow override of startup parameters here?
          take_action('start', RUNNING)
        when 'stop'
          take_action('stop', STOPPED) 
        when 'uninstall', 'delete'
          take_action('stop', STOPPED)
          unless service_exists?
            puts "Service #{CHEF_SERVICE_NAME} doesn't exist on the system."
          else
            ::Win32::Service.delete(CHEF_SERVICE_NAME)
            puts "Service #{CHEF_SERVICE_NAME} deleted"
          end
        when 'pause'
          take_action('pause', PAUSED)
        when 'resume'
          take_action('resume', RUNNING)
        end
      end

      private

      # Just some state constants
      STOPPED = "stopped"
      RUNNING = "running"
      PAUSED = "paused"

      def service_exists?
        return ::Win32::Service.exists?(CHEF_SERVICE_NAME)
      end
      
      def take_action(action=nil, desired_state=nil)
        if service_exists?
          if current_state != desired_state
            ::Win32::Service.send(action, CHEF_SERVICE_NAME)
            wait_for_state(desired_state)
            puts "Service '#{CHEF_SERVICE_NAME}' is now '#{current_state}'."
          else
            puts "Service '#{CHEF_SERVICE_NAME}' is already '#{desired_state}'."
          end
        else
          puts "Cannot '#{action}' service '#{CHEF_SERVICE_NAME}', service does not exist."
        end
      end

      def current_state
        ::Win32::Service.status(CHEF_SERVICE_NAME).current_state
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
