require "chef-utils/dist" unless defined?(ChefUtils::Dist)
class Chef
  module ResourceHelpers
    # Helpers for path manipulation
    module PathHelpers
      extend self
      # The habitat binary path for Infra Client
      # @return [String]
      def chef_client_hab_binary_path
        # Find the most recent version by listing directories
        # This is heavy operation and should be avoided but currently habitat does not create a symlink by default
        # and binlink will be created only if `binlink` option is passed so we cannot assume binlink will be present.
        windows = RUBY_PLATFORM =~ /mswin|mingw|windows/ || defined?(ChefUtils) && ChefUtils.windows?
        base_path = "/hab/pkgs/chef/#{ChefUtils::Dist::Infra::HABITAT_PKG}"
        base_path = "C:/#{base_path}" if windows
        if File.directory?(base_path)
          # Get all version directories
          versions = Dir.glob("#{base_path}/*").select { |d| File.directory?(d) }

          if versions.any?
            # Get the latest version (based on modification time)
            latest_version_dir = versions.max_by { |v| File.mtime(v) }

            # Get all timestamp directories within this version
            timestamps = Dir.glob("#{latest_version_dir}/*").select { |d| File.directory?(d) }

            if timestamps.any?
              # Use the latest timestamp
              latest_dir = timestamps.max_by { |t| File.mtime(t) }
              "#{latest_dir}/bin/#{ChefUtils::Dist::Infra::CLIENT}"
            else
              ""
            end
          end
        else
          ""
        end
      end
    end
  end
end
