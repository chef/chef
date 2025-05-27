require "chef-utils/dist" unless defined?(ChefUtils::Dist)
class Chef
  module ResourceHelpers
    # Helpers for path manipulation
    module PathHelpers
      extend self
      # Returns the path to the active Chef Infra Client binary when installed via Habitat.
      # This method uses following approach to locate the binary:
      #    First, it attempts to find the currently running Chef gem and derives the 
      #    binary path from there. This returns the exact version that's executing.
      # @return [String] The full path to the chef-client binary in the Habitat package,
      #                  or an empty string if the binary cannot be found.
      # @example
      #   chef_client_hab_binary_path
      #   # => "/hab/pkgs/chef/chef-infra-client/19.2.7/20230822151044/bin/chef-client"
      def chef_client_hab_binary_path
        begin
          gem_dir = Gem::Specification.find_by_name("chef").gem_dir.to_s
          windows = RUBY_PLATFORM =~ /mswin|mingw|windows/ || defined?(ChefUtils) && ChefUtils.windows?
          base_path = "/hab/pkgs/chef/#{ChefUtils::Dist::Infra::HABITAT_PKG}"
          base_path = "C:/#{base_path}" if windows
          if gem_dir.include?(base_path)
            # Split on vendor/gems portion
            vendor_split = "/vendor/gems/"
            hab_pkg_path = gem_dir.split(vendor_split).first
            
            # Construct path to binary
            binary_path = File.join(hab_pkg_path, "bin", "#{ChefUtils::Dist::Infra::CLIENT}")
            File.exist?(binary_path) ? binary_path : ""
          else
            ""
          end
        rescue Gem::MissingSpecError, StandardError => e
          ""
        end
      end
    end
  end
end