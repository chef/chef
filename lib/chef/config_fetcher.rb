require "chef/application"
require "chef/chef_fs/path_utils"
require "chef/http/simple"
require "chef/json_compat"

class Chef
  class ConfigFetcher

    attr_reader :config_location

    def initialize(config_location)
      @config_location = config_location
    end

    def expanded_path
      if config_location.nil? || remote_config?
        config_location
      else
        File.expand_path(config_location)
      end
    end

    def fetch_json
      config_data = read_config
      begin
        Chef::JSONCompat.from_json(config_data)
      rescue Chef::Exceptions::JSON::ParseError => error
        Chef::Application.fatal!("Could not parse the provided JSON file (#{config_location}): " + error.message)
      end
    end

    def read_config
      if remote_config?
        fetch_remote_config
      else
        read_local_config
      end
    end

    def fetch_remote_config
      http.get("")
    rescue SocketError, SystemCallError, Net::HTTPServerException => error
      Chef::Application.fatal!("Cannot fetch config '#{config_location}': '#{error.class}: #{error.message}")
    end

    def read_local_config
      ::File.read(config_location)
    rescue Errno::ENOENT
      Chef::Application.fatal!("Cannot load configuration from #{config_location}")
    rescue Errno::EACCES
      Chef::Application.fatal!("Permissions are incorrect on #{config_location}. Please chmod a+r #{config_location}")
    end

    def config_missing?
      return false if remote_config?

      # Check if the config file exists
      Pathname.new(config_location).realpath.to_s
      false
    rescue Errno::ENOENT
      return true
    end

    def http
      Chef::HTTP::Simple.new(config_location)
    end

    def remote_config?
      !!(config_location =~ %r{^(http|https)://})
    end
  end
end
