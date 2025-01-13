require "chef-utils/dist" unless defined?(ChefUtils::Dist)
class Chef
  module ResourceHelpers
    # Helpers for path manipulation
    module PathHelpers
      extend self
      # Returns the path to the Chef Infra Client binary when installed via Habitat.
      # This method attempts to locate the chef-client binary by checking the path
      # of the currently executing program. If the current program's filename
      # matches the Chef client name (e.g., "chef-client"), it returns that path.
      #
      # The method specifically targets scenarios where Chef Infra Client is being
      # run from a Habitat package installation, making it useful for determining
      # the correct binary path in Habitat-managed environments.
      #
      # @return [String] The absolute path to the chef-client binary if found,
      #   or an empty string if no valid binary path is detected.
      # @example
      #   chef_client_hab_binary_path
      #   # => "/hab/pkgs/chef/chef-infra-client/19.10.0/20250822151044/bin/chef-client"
      #   # Or on Windows:
      #   # => "C:/hab/pkgs/chef/chef-infra-client/19.10.0/20250822151044/bin/chef-client"
      def chef_client_hab_binary_path
        puts "*********Fetching binary path"
        path = File.realpath($PROGRAM_NAME)
        puts "************bin path #{path}************"
        bin = File.basename(path)
        puts "************bin name #{bin}************"
        return path if bin == "#{ChefUtils::Dist::Infra::CLIENT}"

        # Return empty string if no valid path is found
        ""
      end
    end
  end
end
