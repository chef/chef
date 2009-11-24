# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2009 Daniel DeLeo
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

require "singleton"
require "pp"
require "etc"
require "mixlib/cli"

require "chef/client"
require "chef/config"

require "chef/shef/shef_session"
require "chef/shef/ext"


module Shef
  LEADERS = Hash.new("")
  LEADERS[Chef::Recipe] = ":recipe"
  LEADERS[Chef::Node]   = ":attributes"
  
  class << self
    attr_accessor :client_type, :options
  end
  
  # Shef assumes it's running whenever it is defined
  def self.running?
    true
  end
  
  # Set the irb_conf object to something other than IRB.conf
  # usful for testing.
  def self.irb_conf=(conf_hash)
    @irb_conf = conf_hash
  end
  
  def self.irb_conf
    @irb_conf || IRB.conf
  end
  
  def self.configure_irb
    irb_conf[:HISTORY_FILE] = "~/.shef_history"
    irb_conf[:SAVE_HISTORY] = 1000
    
    irb_conf[:IRB_RC] = lambda do |conf|
      m = conf.main
      leader = LEADERS[m.class]

      def m.help
        shef_help
      end

      conf.prompt_c       = "chef#{leader} > "
      conf.return_format  = " => %s \n"
      conf.prompt_i       = "chef#{leader} > "
      conf.prompt_n       = "chef#{leader} ?> "
      conf.prompt_s       = "chef#{leader}%l> "
    end
  end
  
  def self.session
    client_type.instance.reset! unless client_type.instance.node_built?
    client_type.instance
  end
  
  def self.init
    parse_json
    configure_irb

    session # trigger ohai run + session load
    
    session.node.consume_attributes(@json_attribs)

    greeting = begin
        " #{Etc.getlogin}@#{Shef.session.node.name}"
      rescue NameError
        ""
      end

    version
    puts

    puts "run `help' for help, `exit' or ^D to quit."
    puts
    puts "Ohai2u#{greeting}!"
  end
  
  def self.parse_json
    if Chef::Config[:json_attribs]
      begin
        json_io = open(Chef::Config[:json_attribs])
      rescue SocketError => error
        fatal!("I cannot connect to #{Chef::Config[:json_attribs]}", 2)
      rescue Errno::ENOENT => error
        fatal!("I cannot find #{Chef::Config[:json_attribs]}", 2)
      rescue Errno::EACCES => error
        fatal!("Permissions are incorrect on #{Chef::Config[:json_attribs]}. Please chmod a+r #{Chef::Config[:json_attribs]}", 2)
      rescue Exception => error
        fatal!("Got an unexpected error reading #{Chef::Config[:json_attribs]}: #{error.message}", 2)
      end

      begin
        @json_attribs = JSON.parse(json_io.read)
      rescue JSON::ParserError => error
        fatal!("Could not parse the provided JSON file (#{Chef::Config[:json_attribs]})!: " + error.message, 2)
      end
    end
  end
  
  def self.fatal!(message, exit_status)
    Chef::Log.fatal(message)
    exit exit_status
  end
  
  def self.client_type
    type = Shef::StandAloneSession
    type = Shef::SoloSession   if Chef::Config[:solo]
    type = Shef::ClientSession if Chef::Config[:client]
    type
  end
  
  def self.parse_opts
    @options = Options.new
    @options.parse_opts
  end
  
  class Options
    include Mixlib::CLI

    option :config_file, 
      :short => "-c CONFIG",
      :long  => "--config CONFIG",
      :description => "The configuration file to use"

    option :help,
      :short        => "-h",
      :long         => "--help",
      :description  => "Show this message",
      :on           => :tail,
      :boolean      => true,
      :show_options => true,
      :exit         => 0

    option :standalone,
      :short        => "-a",
      :long         => "--standalone",
      :description  => "standalone shef session",
      :default      => true,
      :boolean      => true

    option :solo,
      :short        => "-s",
      :long         => "--solo",
      :description  => "chef-solo shef session",
      :boolean      => true

    option :client,
      :short        => "-z",
      :long         => "--client",
      :description  => "chef-client shef session",
      :boolean      => true

    option :json_attribs,
      :short => "-j JSON_ATTRIBS",
      :long => "--json-attributes JSON_ATTRIBS",
      :description => "Load attributes from a JSON file or URL",
      :proc => nil

    option :chef_server_url,
      :short => "-S CHEFSERVERURL",
      :long => "--server CHEFSERVERURL",
      :description => "The chef server URL",
      :proc => nil

    option :version,
      :short        => "-v",
      :long         => "--version",
      :description  => "Show chef version",
      :boolean      => true,
      :proc         => lambda {|v| puts "Chef: #{::Chef::VERSION}"},
      :exit         => 0

    def self.setup!
      self.new.parse_opts
    end

    def parse_opts
      parse_options
      config[:config_file] = config_file_for_shef_mode
      config_msg = config[:config_file] || "none (standalone shef session)"
      puts "loading configuration: #{config_msg}"
      Chef::Config.from_file(config[:config_file]) if !config[:config_file].nil? && File.exists?(config[:config_file]) && File.readable?(config[:config_file])
      Chef::Config.merge!(config)
    end
    
    private
    
    def config_file_for_shef_mode
      return config[:config_file] if config[:config_file]
      return "/etc/chef/solo.rb" if config[:solo]
      return "/etc/chef/client.rb" if config[:client]
      nil
    end

  end
  
end