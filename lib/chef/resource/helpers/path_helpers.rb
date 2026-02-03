require "chef/mixin/which"

class Chef
  module ResourceHelpers
    # Helpers for path manipulation
    module PathHelpers
      extend self
      include Chef::Mixin::Which

      # This method returns the absolute path to the chef-client binary that is currently executing.
      # In a Habitat environment, you might have multiple versions of chef-client installed,
      # we want to ensure we get the path to the one currently running.
      #
      # @return [String] The absolute path to the chef-client binary if found,
      #   or an empty string if no valid binary path is detected.
      # @example
      #   chef_client_hab_binary_path
      #   # => "/hab/pkgs/chef/chef-infra-client/19.10.0/20250822151044/bin/chef-client"
      #   # Or on Windows:
      #   # => "C:/hab/pkgs/chef/chef-infra-client/19.10.0/20250822151044/bin/chef-client"
      def chef_client_hab_binary_path
        path = File.realpath($PROGRAM_NAME)
        bin = File.basename(path)

        # On Windows, prefer the PowerShell wrapper if it exists and we're running chef-client
        # because hab pkg .bat binstubs getting the pathing correct is a challenge.
        if bin == "#{ChefUtils::Dist::Infra::CLIENT}"
          ps1_path = 'C:\hab\chef\bin\chef-client.ps1'
          return ps1_path if File.exist?(ps1_path) && ChefUtils.windows?
          return path
        end

        # Return empty string if no valid path is found
        ""
      end

      def hab_executable_binary_path
        # Find hab in PATH
        which("hab") || ""
      end
    end
  end
end
