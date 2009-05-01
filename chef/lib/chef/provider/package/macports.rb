class Chef
  class Provider
    class Package
      class Macports < Chef::Provider::Package
        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)

          @current_resource.version(current_installed_version)
          Chef::Log.debug("Current version is #{@current_resource.version}") if @current_resource.version

          @candidate_version = macports_candidate_version
          Chef::Log.debug("MacPorts candidate version is #{@candidate_version}") if @candidate_version

          @current_resource
        end

        def current_installed_version
          command = "port installed #{@new_resource.package_name} | grep \"(active)\""
          output = get_line_from_command(command)

          if output.empty?
            nil
          else
            match = output.match(/^.+ @([^\s]+) \(active\)$/)
            match[1]
          end
        end

        def macports_candidate_version
          command = "port info --version #{@new_resource.package_name}"
          output = get_line_from_command(command)

          match = output.match(/^version: (.+)$/)

          match ? match[1] : nil
        end

        def install_package(name, version)
          unless @current_resource.version == version
            run_command(
              :command => "port install #{name} @#{version}"
            )
          end
        end

        def purge_package(name, version)
          run_command(
            :command => "port uninstall #{name} @#{version}"
          )
        end

        def remove_package(name, version)
          run_command(
            :command => "port deactivate #{name} @#{version}"
          )
        end

        def upgrade_package(name, version)
          unless @current_resource.version == version
            run_command(
              :command => "port upgrade #{name} @#{version}"
            )
          end
        end

        private
        def get_line_from_command(command)
          output = nil
          status = popen4(command) do |pid, stdin, stdout, stderr|
            output = stdout.readline.strip
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
