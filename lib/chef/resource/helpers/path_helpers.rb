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
        return path if bin == "#{ChefUtils::Dist::Infra::CLIENT}"

        # Return empty string if no valid path is found
        ""
      end

      def hab_executable_binary_path
        # Only proceed if running from a Habitat package
        current_path = File.realpath($PROGRAM_NAME)
        unless current_path.match?(%r{/[\/\\]hab[\/\\]pkgs[\/\\]/})
          return ""
        end

        # Find hab in PATH
        hab_bin = find_executable("hab")
        return hab_bin if hab_bin

        ""
      end

      private

      def find_executable(name)
        # On Windows, also check with .exe if not provided
        names_to_check = [name]
        names_to_check << "#{name}.exe" if ChefUtils.windows? && !name.end_with?(".exe")

        # Search through PATH
        ENV["PATH"].split(File::PATH_SEPARATOR).each do |dir|
          names_to_check.each do |exe_name|
            exe_path = File.join(dir, exe_name)
            return exe_path if File.exist?(exe_path)
          end
        end

        nil
      end
    end
  end
end
