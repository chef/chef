#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

require "chef-config/config"
require "chef-config/exceptions"
require "chef-config/logger"
require "chef-config/path_helper"
require "chef-config/windows"

module ChefConfig
  class WorkstationConfigLoader

    # Path to a config file requested by user, (e.g., via command line option). Can be nil
    attr_accessor :explicit_config_file

    # TODO: initialize this with a logger for Chef and Knife
    def initialize(explicit_config_file, logger = nil)
      @explicit_config_file = explicit_config_file
      @chef_config_dir = nil
      @config_location = nil
      @logger = logger || NullLogger.new
    end

    def no_config_found?
      config_location.nil?
    end

    def config_location
      @config_location ||= (explicit_config_file || locate_local_config)
    end

    def chef_config_dir
      if @chef_config_dir.nil?
        @chef_config_dir = false
        full_path = working_directory.split(File::SEPARATOR)
        (full_path.length - 1).downto(0) do |i|
          candidate_directory = File.join(full_path[0..i] + [".chef"])
          if File.exist?(candidate_directory) && File.directory?(candidate_directory)
            @chef_config_dir = candidate_directory
            break
          end
        end
      end
      @chef_config_dir
    end

    def load
      # Ignore it if there's no explicit_config_file and can't find one at a
      # default path.
      if !config_location.nil?
        if explicit_config_file && !path_exists?(config_location)
          raise ChefConfig::ConfigurationError, "Specified config file #{config_location} does not exist"
        end

        # Have to set Config.config_file b/c other config is derived from it.
        Config.config_file = config_location
        read_config(IO.read(config_location), config_location)
      end

      load_conf_d_directory
    end

    # (Private API, public for test purposes)
    def env
      ENV
    end

    # (Private API, public for test purposes)
    def path_exists?(path)
      Pathname.new(path).expand_path.exist?
    end

    private

    def have_config?(path)
      if path_exists?(path)
        logger.info("Using config at #{path}")
        true
      else
        logger.debug("Config not found at #{path}, trying next option")
        false
      end
    end

    def locate_local_config
      candidate_configs = []

      # Look for $KNIFE_HOME/knife.rb (allow multiple knives config on same machine)
      if env["KNIFE_HOME"]
        candidate_configs << File.join(env["KNIFE_HOME"], "config.rb")
        candidate_configs << File.join(env["KNIFE_HOME"], "knife.rb")
      end
      # Look for $PWD/knife.rb
      if Dir.pwd
        candidate_configs << File.join(Dir.pwd, "config.rb")
        candidate_configs << File.join(Dir.pwd, "knife.rb")
      end
      # Look for $UPWARD/.chef/knife.rb
      if chef_config_dir
        candidate_configs << File.join(chef_config_dir, "config.rb")
        candidate_configs << File.join(chef_config_dir, "knife.rb")
      end
      # Look for $HOME/.chef/knife.rb
      PathHelper.home(".chef") do |dot_chef_dir|
        candidate_configs << File.join(dot_chef_dir, "config.rb")
        candidate_configs << File.join(dot_chef_dir, "knife.rb")
      end

      candidate_configs.find do |candidate_config|
        have_config?(candidate_config)
      end
    end

    def load_conf_d_directory
      conf_d_files.sort.map do |conf|
        read_config(IO.read(conf), conf)
      end
    end

    def conf_d_files
      @conf_d_files ||=
        begin
          entries = Array.new
          entries << Dir.glob(File.join(PathHelper.escape_glob_dir(
            Config[:conf_d_dir]), "*.rb")) if Config[:conf_d_dir]
          entries.flatten.select do |entry|
            File.file?(entry)
          end
        end
    end

    def working_directory
      a = if ChefConfig.windows?
            env["CD"]
          else
            env["PWD"]
          end || Dir.pwd

      a
    end

    def read_config(config_content, config_file_path)
      Config.from_string(config_content, config_file_path)
    rescue SignalException
      raise
    rescue SyntaxError => e
      message = ""
      message << "You have invalid ruby syntax in your config file #{config_file_path}\n\n"
      message << "#{e.class.name}: #{e.message}\n"
      if file_line = e.message[/#{Regexp.escape(config_file_path)}:[\d]+/]
        line = file_line[/:([\d]+)$/, 1].to_i
        message << highlight_config_error(config_file_path, line)
      end
      raise ChefConfig::ConfigurationError, message
    rescue Exception => e
      message = "You have an error in your config file #{config_file_path}\n\n"
      message << "#{e.class.name}: #{e.message}\n"
      filtered_trace = e.backtrace.grep(/#{Regexp.escape(config_file_path)}/)
      filtered_trace.each { |bt_line| message << "  " << bt_line << "\n" }
      if !filtered_trace.empty?
        line_nr = filtered_trace.first[/#{Regexp.escape(config_file_path)}:([\d]+)/, 1]
        message << highlight_config_error(config_file_path, line_nr.to_i)
      end
      raise ChefConfig::ConfigurationError, message
    end

    def highlight_config_error(file, line)
      config_file_lines = []
      IO.readlines(file).each_with_index { |l, i| config_file_lines << "#{(i + 1).to_s.rjust(3)}: #{l.chomp}" }
      if line == 1
        lines = config_file_lines[0..3]
      else
        lines = config_file_lines[Range.new(line - 2, line)]
      end
      "Relevant file content:\n" + lines.join("\n") + "\n"
    end

    def logger
      @logger
    end

  end
end
