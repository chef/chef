require 'chef/mixin/windows_architecture_helper'
require "chef/mixin/shell_out"
require 'chef/util/path_helper'

class Chef
  class Provider
    class Package
      class Windows
        class CAB
          include Chef::Mixin::ShellOut
          include Chef::Mixin::WindowsArchitectureHelper

          def initialize(resource)
            @new_resource = resource
          end

          attr_reader :new_resource

          def installed_version
            Chef::Log.debug("#{@new_resource} getting product version for package at #{@new_resource.source}")
            stdout = dism_command("/Get-PackageInfo /PackagePath:\"#{@new_resource.source}\"").stdout
            package_info = parse_dism_get_package_info(stdout)
            # e.g. Package_for_KB2975719~31bf3856ad364e35~amd64~~6.3.1.8
            package = split_package_identity(package_info['package_information']['package_identity'])
            # Search for just the package name to catch a different version being installed
            Chef::Log.debug("#{@new_resource} searching for installed package #{package['name']}")
            found_packages = installed_packages.select { |p| p['package_identity'] =~ /^#{package['name']}~/ }
            if found_packages.length == 0
             nil
            elsif found_packages.length == 1
             package['version']
            else
             # Presuming this won't happen, otherwise we need to handle it
             raise Chef::Exceptions::Package, "Found mutliple packages installed matching name #{package['name']}, found: #{found_packages.length} matches"
            end
          end

          def package_version
            Chef::Log.debug("#{@new_resource} getting product version for package at #{@new_resource.source}")
            stdout = dism_command("/Get-PackageInfo /PackagePath:\"#{@new_resource.source}\"").stdout
            package_info = parse_dism_get_package_info(stdout)
            package = split_package_identity(package_info['package_information']['package_identity'])
            package['version']
          end

          def install_package
            Chef::Log.info("#{@new_resource} installing Windows CAB package '#{@new_resource.source}'")
            dism_command("/Add-Package /PackagePath:\"#{@new_resource.source}\"")
          end

          def remove_package
            Chef::Log.debug("#{@new_resource} removing Windows CAB package '#{@new_resource.source}'")
            dism_command("/Remove-Package /PackagePath:\"#{@new_resource.source}\"")
          end

          # Runs a command through DISM, and returns a Mixlib::ShellOut object
          # For example, output can be accessed like dism_command("/Get-CurrentEdition").stdout
          def dism_command(command)
            shellout = Mixlib::ShellOut.new("dism.exe /Online #{command} /NoRestart", {:timeout => @new_resource.timeout, :returns => @new_resource.returns})
            with_os_architecture(@node) do
              shellout.run_command
            end
          end

          # returns a hash of package state information given the output of dism /get-packages
          # expected keys: package_identity, state, release_type, install_time
          def parse_dism_get_packages(text)
            packages = Array.new
            package = Hash.new
            inside_package_listing = false
            text.each_line do |line|
              # Skip the headers
              if line =~ /^Packages listing:/
                inside_package_listing = true
                next
              end

              next unless inside_package_listing

              if line.chomp.empty?
                # Between packages so save it to the collection
                unless package.empty?
                  packages << package
                  package = Hash.new
                end
              end

              if line =~ /(.*) : (.*)/
                v = $2.chomp # has to be first or the gsub below replaces this variable
                k = $1.downcase.strip.gsub(/ /,"_")
                package[k] = v
              end
            end
            packages
          end

          # returns a hash of package information given the output of dism /get-packageinfo
          def parse_dism_get_package_info(text)
            package_data = Hash.new
            errors = Array.new
            in_section = false
            # Version/Image Version are Windows Versions
            # TODO: Verfiy we're parsing Features in a useful way
            section_headers = [ "Package information", "Custom Properties", "Features" ]

            text.each_line do |line|
              if line =~ /Error: (.*)/
                errors << $1
              elsif section_headers.any? { |header| line =~ /^(#{header})/ }
                in_section = $1.downcase.gsub(/ /,"_")
              elsif line =~ /(.*) ?: (.*)/
                v = $2 # has to be first or the gsub below replaces this variable
                k = $1.downcase.strip.gsub(/ /,"_")
                if in_section
                  package_data[in_section] = Hash.new unless package_data[in_section]
                  package_data[in_section][k] = v
                else
                  package_data[k] = v
                end
              end
            end

            unless errors.empty?
              if errors.include?("87")
                Chef::Log.debug("DISM: Error 87: Package unknown (not installed)")
                return nil
              else
                raise Chef::Exceptions::Package, "Unknown errors encountered parsing DISM output: #{errors}"
              end
            end
            package_data
          end

          def split_package_identity(identity)
            data = Hash.new
            data['name'], data['publisher'], data['arch'], data['resource_id'], data['version'] = identity.split('~')
            data
          end

          def installed_packages
            @@package_cache ||= begin
              # TODO: A resource attribute to invalidate the cache
              output = dism_command("/Get-Packages").stdout
                packages = parse_dism_get_packages(output)
                packages
            end
          end
        end
      end
    end
  end
end
