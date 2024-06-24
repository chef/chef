# frozen_string_literal: true
require "chef-licensing"
require "securerandom" unless defined?(SecureRandom)
require "digest" unless defined?(Digest)
require "chef-utils/dist" unless defined?(ChefUtils::Dist)
require_relative "../telemetry/run_context_probe" unless defined?(Chef::Telemetry::RunContextProbe)

class Chef
  class Telemetry
    class Base
      VERSION = 2.0
      TYPE = "job"
      JOB_TYPE = "Chef Infra" # Need to confirm

      attr_accessor :scratch

      def fetch_license_ids
        Chef::Log.debug "Fetching license IDs for telemetry"
        @license_keys ||= ChefLicensing.license_keys
      end

      def create_wrapper
        Chef::Log.debug "Initialising wrapper for telemetry"
        {
          version: VERSION,
          createdTimeUTC: Time.now.getutc.iso8601,
          environment: Chef::Telemetry::RunContextProbe.guess_run_context,
          licenseIds: fetch_license_ids,
          source: "", #TODO
          type: TYPE,
        }
      end

      def run_starting(_opts = {}); end

      def run_ending(opts)
        payload = create_wrapper

        payload[:platform] = "" #TODO

        payload[:jobs] = [{
                            type: JOB_TYPE,
                            # Target platform info
                            environment: {
                              host: "", #TODO
                              os: "", #TODO
                              version: "", #TODO
                              architecture: "", #TODO
                              id: "", #TODO
                            },
                            runtime: Chef::VERSION,
                            content: [], #TODO
                            steps: [], #TODO
                          }]

        Chef::Log.debug "Final data for telemetry upload -> #{payload}"
        # Return payload object for testing
        payload
      end

      # Hash text if non-nil
      def obscure(cleartext)
        return nil if cleartext.nil?
        return nil if cleartext.empty?

        Digest::SHA2.new(256).hexdigest(cleartext)
      end
    end
  end
end
