# frozen_string_literal: true
require_relative "base"
require "faraday" unless defined?(Faraday)
require_relative "../licensing_config"
class Chef
  class Telemetry
    class HTTP < Base
      TELEMETRY_JOBS_PATH = "v1/job"
      TELEMETRY_URL = if ChefLicensing::Config.license_server_url&.match?("acceptance")
                        ENV["CHEF_TELEMETRY_URL"]
                      else
                        "https://services.chef.io/telemetry/"
                      end
      def run_ending(opts)
        payload = super
        response = connection.post(TELEMETRY_JOBS_PATH) do |req|
          req.body = payload.to_json
        end
        if response.success?
          Chef::Log.debug "HTTP connection with Telemetry Client successful."
          Chef::Log.debug "HTTP response from Telemetry Client -> #{response.to_hash}"
          true
        else
          Chef::Log.debug "HTTP connection with Telemetry Client faced an error."
          Chef::Log.debug "HTTP error -> #{response.to_hash[:body]["error"]}" if response.to_hash[:body] && response.to_hash[:body]["error"]
          false
        end
      rescue Faraday::ConnectionFailed
        Chef::Log.debug "HTTP connection failure with telemetry url -> #{TELEMETRY_URL}"
      end

      def connection
        Faraday.new(url: TELEMETRY_URL) do |config|
          config.request :json
          config.response :json
        end
      end
    end
  end
end
