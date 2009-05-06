#
# Author:: AJ Christensen (<aj@junglist.gen.nz>)
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

require 'optparse'
require 'chef'
require 'chef/exceptions'
require 'chef/logger'

class Chef::Application
  attr_accessor :argv, :config, :options, :opt_parser
  
  def initialize()
    @argv = ARGV.dup
    @config = { :config_file => "/etc/chef/default.rb" }
    @options = nil
    @opt_parser = nil
    
    trap("INT") do
       Chef.fatal!("SIGINT received, stopping", 2)
    end
    
    trap("HUP") do 
      Chef::Log.info("SIGHUP received, reconfiguring")
      reconfigure
    end
    
    at_exit do
      # tear down the logger and shit
    end
        
  end
  
  def reconfigure
    configure_opt_parser
    configure_chef
    parse_arguments
    configure_logging
  end
  
  def run
    reconfigure
    get_this_party_started
  end
  
  def configure_opt_parser    
    @opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} (options)"

      default_options = { 
        :config_file => {
          :short => "-c CONFIG",
          :long => "--config CONFIG",
          :description => "The Chef Config file to use",
          :proc => nil }, 
        :log_level => { 
          :short => "-l LEVEL",
          :long => "--loglevel LEVEL",
          :description => "Set the log level (debug, info, warn, error, fatal)",
          :proc => lambda { |p| p.to_sym} },
        :log_location => {
          :short => "-L LOGLOCATION",
          :long => "--logfile LOGLOCATION",
          :description => "Set the log file location, defaults to STDOUT - recommended for daemonizing",
          :proc => nil }
      }
      
      # just a step to the left
      @options = default_options.merge(@options) if @options

      # setup our instance config hash
      @options.each do |opt_key, opt_val|
        opts.on(opt_val[:short], opt_val[:long], opt_val[:description]) do |c|
          @config[opt_key] = (opt_val[:proc] && opt_val[:proc].call(c)) || c
        end
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit 0
      end
    end
  end
  
  # Parse the configuration file
  def configure_chef
    Chef::Config.from_file(@config[:config_file])
    Chef::Config.configure { |c| c.merge!(@config).rehash }
  end
  
  # Initialize and configure the logger
  def configure_logging
    Chef::Log.init(Chef::Config[:log_location])
    Chef::Log.level(Chef::Config[:log_level])
  end
  
  # Parse ARGV for arguments
  def parse_arguments
    raise Chef::Exceptions::Application, "#{self.to_s}: option parser has not been configured" unless @opt_parser
    @opt_parser.parse!(@argv)
  end
  
  # Log a fatal error message and exit the process
  def fatal!(msg, err = -1)
    Chef::Log.fatal(msg)
    exit err
  end
  
  private
  
  def get_this_party_started
    raise Chef::Exceptions::Application, "#{self.to_s}: you must override get_this_party_started"
  end

end


Chef::Application.new.run