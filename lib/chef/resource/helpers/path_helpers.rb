require "chef-utils/dist" unless defined?(ChefUtils::Dist)
class Chef
  module ResourceHelpers
    # Helpers for path manipulation
    module PathHelpers
      extend self
      # Returns the path to the Chef Infra Client binary when installed via Habitat.
      # This method first checks for binlinks created during Habitat package installation.
      # If no binlink is found, it falls back to checking the currently running script's path.
      #
      # @return [String] The path to the chef-client binary, or an empty string if not found.
      # @example
      #   chef_client_hab_binary_path
      #   # => "/bin/chef-client" (Linux)
      #   # => "C:/hab/bin/chef-client.bat" (Windows)
      def chef_client_hab_binary_path
        client_name = ChefUtils::Dist::Infra::CLIENT
        windows = RUBY_PLATFORM =~ /mswin|mingw|windows/ || defined?(ChefUtils) && ChefUtils.windows?

        # Default binlink paths
        binlink_path = if windows
                         "C:/hab/bin/#{client_name}.bat"  # Default binlink location on Windows
                       else
                         "/bin/#{client_name}"            # Default binlink location on Linux
                       end

        # Return the path if the binlink exists
        return binlink_path if File.exist?(binlink_path)

        # Fallback to the currently running script's path
        path = File.realpath($PROGRAM_NAME)
        bin = File.basename(path)
        return path if bin == client_name

        # Return empty string if no valid path is found
        ""
      end
    end
  end
end
