require "chef/mixin/which"
require "pathname" unless defined?(Pathname)

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

        # On Windows, temporarily use the c:\\hab\\bin\\*.bat binstubs
        bat_path = "C:\\hab\\bin\\#{ChefUtils::Dist::Infra::CLIENT}.bat"
        return bat_path if File.exist?(bat_path) && ChefUtils.windows?

        # return path for any bin/chef-* names
        return path.sub(bin, ChefUtils::Dist::Infra::CLIENT) if bin =~ /^chef-[a-z-]+$/

        # Return empty string if no valid path is found
        ""
      end

      # once the binstubs under hab package have been fixed,
      # restore this as the chef_client_hab_binary_path method
      def chef_client_hab_package_binary_path
        path = File.realpath($PROGRAM_NAME)
        bin = File.basename(path)

        if bin =~ /^chef-[a-z-]+$/
          return path.sub(bin, ChefUtils::Dist::Infra::CLIENT) if ChefUtils.windows?

          return "hab pkg exec #{chef_client_hab_package_ident} #{ChefUtils::Dist::Infra::CLIENT}"
        end

        # Return empty string if no valid path is found
        ""
      end

      # Returns the Habitat package identifier (origin/name/version/release) for the
      # currently running Chef Infra Client package.
      #
      # @return [String] the hab package ident, e.g. "chef/chef-infra-client/19.10.0/20250822151044",
      #   or an empty string if not running from a hab package.
      def chef_client_hab_package_ident
        path = File.realpath($PROGRAM_NAME)
        bin = File.basename(path)
        return "" unless bin =~ /^chef-[a-z-]+$/

        Pathname.new(path).each_filename.to_a[2..5].join("/")
      end

      def hab_executable_binary_path
        # Find hab in PATH
        which("hab") || ""
      end
    end
  end
end
