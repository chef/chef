class Chef
  class Provider
    class Package
      class Macports < Chef::Provider::Package

        provides :package, os: "darwin"
        provides :macports_package

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)

          current_resource.version(current_installed_version)
          Chef::Log.debug("#{new_resource} current version is #{current_resource.version}") if current_resource.version

          @candidate_version = macports_candidate_version

          if !new_resource.version && !@candidate_version
            raise Chef::Exceptions::Package, "Could not get a candidate version for this package -- #{new_resource.name} does not seem to be a valid package!"
          end

          Chef::Log.debug("#{new_resource} candidate version is #{@candidate_version}") if @candidate_version

          current_resource
        end

        def current_installed_version
          command = [ "port", "installed", new_resource.package_name ]
          output = get_response_from_command(command)

          response = nil
          output.each_line do |line|
            match = line.match(/^.+ @([^\s]+) \(active\)$/)
            response = match[1] if match
          end
          response
        end

        def macports_candidate_version
          command = [ "port", "info", "--version", new_resource.package_name ]
          output = get_response_from_command(command)

          match = output.match(/^version: (.+)$/)

          match ? match[1] : nil
        end

        def install_package(name, version)
          unless current_resource.version == version
            command = [ "port", options, "install", name ]
            command << "@#{version}" if version && !version.empty?
            shell_out_compact_timeout!(command)
          end
        end

        def purge_package(name, version)
          command = [ "port", options, "uninstall", name ]
          command << "@#{version}" if version && !version.empty?
          shell_out_compact_timeout!(command)
        end

        def remove_package(name, version)
          command = [ "port", options, "deactivate", name ]
          command << "@#{version}" if version && !version.empty?

          shell_out_compact_timeout!(command)
        end

        def upgrade_package(name, version)
          # Saving this to a variable -- weird rSpec behavior
          # happens otherwise...
          current_version = current_resource.version

          if current_version.nil? || current_version.empty?
            # Macports doesn't like when you upgrade a package
            # that hasn't been installed.
            install_package(name, version)
          elsif current_version != version
            shell_out_compact_timeout!( "port", options, "upgrade", name, "@#{version}" )
          end
        end

        private

        def get_response_from_command(command)
          output = nil
          status = shell_out_compact_timeout(command)
          begin
            output = status.stdout
          rescue Exception
            raise Chef::Exceptions::Package, "Could not read from STDOUT on command: #{command}"
          end
          unless status.exitstatus == 0 || status.exitstatus == 1
            raise Chef::Exceptions::Package, "#{command} failed - #{status.insect}!"
          end
          output
        end
      end
    end
  end
end
