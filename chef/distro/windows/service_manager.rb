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
require 'rbconfig'
require 'mixlib/cli'

class Chef
  class Windows
    class ServiceManager
      include Config
      include Mixlib::CLI

      option :action,
        :short => "-a ACTION",
        :long  => "--action ACTION",
        :default => "start",
        :description => "Action to carry out on the resource; one of 'install', 'uninstall', 'start', 'stop', 'pause', or 'resume'"

      option :name,
        :short => "-n NAME",
        :long  => "--name NAME",
        :default => "chef-client",
        :description => "The service name to use."

      option :display_name,
        :long  => "--display_name NAME",
        :default => "chef-client",
        :description => "The display name to use for the service."

      option :description,
        :short => "-d DESCRIPTION",
        :long  => "--description DESCRIPTION",
        :default => "chef-client",
        :description => "The description for the service."

      option :config_file,
        :short => "-c CONFIG",
        :long  => "--config CONFIG",
        :default => "#{ENV['SYSTEMDRIVE']}/chef/client.rb",
        :description => "The configuration file to use"

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

      option :help,
        :short        => "-h",
        :long         => "--help",
        :description  => "Show this message",
        :on           => :tail,
        :boolean      => true,
        :show_options => true,
        :exit         => 0

      def run
        parse_options

        case config[:action]
        when 'install'

          # Quote the full path to deal with possible spaces in the path name.
          ruby = File.join(RbConfig::CONFIG['bindir'], 'ruby')
          path = ' "' + File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'chef', 'application', 'windows_service.rb')) + '"'
          # ensure all forward slashes are backslashes
          options = " -c #{config[:config_file]} -L #{config[:log_location]} -i #{config[:interval]} -s #{config[:splay]}"
          cmd = (ruby + path + options).gsub(File::SEPARATOR, File::ALT_SEPARATOR)

          Win32::Service.new(
                      :service_name     => config[:name],
                      :display_name     => config[:display_name],
                      :description      => config[:description],
                      :binary_path_name => cmd)

        when 'start'
          # TODO: allow override of startup parameters here?
          take_action('start', RUNNING)
        when 'stop'
          take_action('stop', STOPPED)
        when 'uninstall', 'delete'
          take_action('stop', STOPPED)
          Win32::Service.delete(config[:name])
          puts "Service #{config[:name]} deleted"
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

      def take_action(action=nil, desired_state=nil)
        if current_state != desired_state
          Win32::Service.send(action, config[:name])
          wait_for_state(desired_state)
          puts "Service #{config[:name]} is now #{current_state}"
        else
          puts "Already #{desired_state}"
        end
      end

      def current_state
        Win32::Service.status(config[:name]).current_state
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

Chef::Windows::ServiceManager.new.run
