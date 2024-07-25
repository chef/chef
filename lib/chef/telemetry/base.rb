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
      JOB_TYPE = "Infra"

      attr_accessor :scratch, :ohai

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
          source: "#{ChefUtils::Dist::Infra::EXEC}:#{Chef::VERSION}",
          type: TYPE,
        }
      end

      def run_starting(_opts = {})
        Chef::Log.debug "Initiating telemetry for Chef"
      end

      def run_ending(opts)
        payload = create_wrapper

        # To not load ohai information once loaded
        unless ohai
          @ohai = Ohai::System.new
          # Load lugins to gather system data
          @ohai.all_plugins(%w{ os hostname platform dmi kernel})
        end

        payload[:platform] = ohai[:platform]

        payload[:jobs] = [{
                            type: JOB_TYPE,
                            # Target platform info
                            environment: {
                              host: ohai[:hostname],
                              os: ohai[:os],
                              version: ohai[:platform_version],
                              architecture: ohai[:kernel][:machine],
                              id: (ohai[:dmi][:system] && ohai[:dmi][:system][:uuid]) || "",
                            },
                            runtime: Chef::VERSION,
                            content: [],
                            steps: [],
                          }]

        if opts[:run_context]
          opts[:run_context].cookbook_collection.each do |_, value|
            metadata = value.metadata
            payload[:jobs][0][:content] << {
              name: obscure(metadata&.name) || "",
              version: metadata&.version || "",
              maintainer: metadata&.maintainer || "",
              type: "cookbook",
            }
          end
          if opts[:run_context].resource_collection&.all_resources
            opts[:run_context].resource_collection.all_resources.each do |resource|
              payload[:jobs][0][:steps] << {
                name: resource.recipe_name,
                resources: [],
              }

              payload[:jobs][0][:steps].last[:resources] << {
                type: "chef-resource",
                name: resource.resource_name.to_s,
              }
            end
          end
        end
        Chef::Log.debug "Final data for telemetry upload -> #{payload}"
        Chef::Log.debug "Finishing telemetry for Chef"
        # Return payload object for testing
        payload
      end

      # TBD Should we implement distrbution name based on below usage?
      def determine_distribution_name
        run_context = Chef::Telemetry::RunContextProbe.guess_run_context
        case run_context
        when "chef-zero"
          ChefUtils::Dist::Zero::EXEC
        when "chef-apply"
          ChefUtils::Dist::Apply::EXEC
        when "chef-solo"
          ChefUtils::Dist::Solo::EXEC
        else
          ChefUtils::Dist::Infra::EXEC
        end
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
