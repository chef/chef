require_relative "log"
require "time" unless defined?(Time.zone_offset)
require "chef-licensing"
require_relative "telemetry/null"
require_relative "telemetry/http"
# require_relative "telemetry/run_context_probe" TODO

class Chef
  class Telemetry

    @@instance = nil

    def self.instance
      @@instance ||= determine_backend_class.new
    end

    def self.determine_backend_class
      # TODO Determine check for automate or hab or other distros
      if license&.license_type&.downcase == "commercial"
        return Chef::Telemetry::Null
      end

      Chef::Log.debug "Determined HTTP instance for telemetry"
      Chef::Telemetry::HTTP
    end

    def self.license
      Chef::Log.debug "Fetching license context for telemetry"
      @license = ChefLicensing.license_context
    end

    ######
    # These class methods make it convenient to call from anywhere within the Chef codebase.
    ######
    def self.run_starting(opts)
      Chef::Log.debug "Initiating telemetry for Chef"
      instance.run_starting(opts)
    rescue StandardError => e
      Chef::Log.debug "Encountered error in Telemetry start run call -> #{e.message}"
    end

    def self.run_ending(opts)
      instance.run_ending(opts)
      Chef::Log.debug "Finishing telemetry for Chef"
    rescue StandardError => e
      Chef::Log.debug "Encountered error in Telemetry end run call -> #{e.message}"
    end
  end
end
