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

      attr_accessor :ohai

      def fetch_license_ids
        Chef::Log.debug "Fetching license IDs for telemetry"
        @license_keys ||= ChefLicensing.license_keys
      end

      def create_wrapper
        Chef::Log.debug "Initializing wrapper for telemetry"
        run_context = Chef::Telemetry::RunContextProbe.guess_run_context
        {
          version: VERSION,
          createdTimeUTC: Time.now.getutc.iso8601,
          environment: Chef::Config.target_mode? ? "#{run_context}:target-mode" : run_context,
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

        @ohai = Ohai::System.new
        # Load plugins to gather system data
        @ohai.all_plugins(%w{ os hostname platform dmi kernel})

        payload[:platform] = ohai[:platform]
        hostname = Chef::Config.target_mode? ? Chef::Config.target_mode.host : ohai[:hostname]
        payload[:jobs] = [{
                            type: JOB_TYPE,
                            # Target platform info
                            environment: {
                              host: obscure(hostname),
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
              type: "cookbook",
            }
          end
          all_resources = opts[:run_context].resource_collection&.all_resources
          seen_resources = {} # A hash to keep track of resource types that have been added
          if all_resources
            all_resources.each do |resource|
              # Determine if the resource is a Chef resource or a custom one
              resource_type = resource_is_a_chef_resource?(resource) ? resource.resource_name.to_s : "HWLR"

              # If the resource type hasn't been tracked yet, initialize it within payload
              unless seen_resources[resource_type]
                step_name = resource_is_a_chef_resource?(resource) ? "Chef Resources" : "Custom Resources"

                # Add a step for Chef or Custom resources if it doesn’t already exist
                step = payload[:jobs][0][:steps].find { |s| s[:name] == step_name }
                step ||= { name: step_name, resources: [] }
                payload[:jobs][0][:steps] << step unless payload[:jobs][0][:steps].include?(step)

                # Append a new resource type within this step and initialize the count
                step[:resources] << { type: resource_type, count: 0 }
                # Reference this resource type for further count accumulation
                seen_resources[resource_type] = step[:resources].last
              end

              # Increment the count for each occurrence of this resource type
              seen_resources[resource_type][:count] += 1
            end
          end
        end
        Chef::Log.debug "Final data for telemetry upload -> #{payload}"
        Chef::Log.debug "Finishing telemetry for Chef"
        # Return payload object for testing
        payload
      end

      def resource_is_a_chef_resource?(resource)
        resource_action_class_name = resource.class.action_class.to_s
        resource_action_class_name.include?("Chef::Resource") && !resource_action_class_name.include?("Custom")
      end

      # TBD Should we implement distribution name based on below usage?
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
