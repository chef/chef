require 'chef/mixin/shell_out'

class Chef
  class Provider
    class Package
      class Yum
        # Cache for our installed and available packages, pulled in from yum-dump.py
        class YumCache
          include Chef::Mixin::ShellOut
          include Singleton

          def initialize
            @rpmdb = RPMDb.new

            # Next time @rpmdb is accessed:
            #  :all       - Trigger a run of "yum-dump.py --options --installed-provides", updates
            #               yum's cache and parses options from /etc/yum.conf. Pulls in Provides
            #               dependency data for installed packages only - this data is slow to
            #               gather.
            #  :provides  - Same as :all but pulls in Provides data for available packages as well.
            #               Used as a last resort when we can't find a Provides match.
            #  :installed - Trigger a run of "yum-dump.py --installed", only reads the local rpm
            #               db. Used between client runs for a quick refresh.
            #  :none      - Do nothing, a call to one of the reload methods is required.
            @next_refresh = :all

            @allow_multi_install = []

            # these are for subsequent runs if we are on an interval
            Chef::Client.when_run_starts do
              YumCache.instance.reload
            end
          end

          # Cache management
          #

          def refresh
            case @next_refresh
            when :none
              return nil
            when :installed
              reset_installed
              # fast
              opts=" --installed"
            when :all
              reset
              # medium
              opts=" --options --installed-provides"
            when :provides
              reset
              # slow!
              opts=" --options --all-provides"
            else
              raise ArgumentError, "Unexpected value in next_refresh: #{@next_refresh}"
            end

            one_line = false
            error = nil

            helper = ::File.join(::File.dirname(__FILE__), 'yum-dump.py')

            status = shell_out!("/usr/bin/python #{helper}#{opts}")
            status.stdout.each_line do |line|
              one_line = true

              line.chomp!

              if line =~ %r{\[option (.*)\] (.*)}
                if $1 == "installonlypkgs"
                  @allow_multi_install = $2.split
                else
                  raise Chef::Exceptions::Package, "Strange, unknown option line '#{line}' from yum-dump.py"
                end
                next
              end

              if line =~ %r{^(\S+) ([0-9]+) (\S+) (\S+) (\S+) \[(.*)\] ([i,a,r]) (\S+)$}
                name     = $1
                epoch    = $2
                version  = $3
                release  = $4
                arch     = $5
                provides = parse_provides($6)
                type     = $7
                repoid   = $8
              else
                Chef::Log.warn("Problem parsing line '#{line}' from yum-dump.py! " +
                               "Please check your yum configuration.")
                next
              end

              case type
              when "i"
                # if yum-dump was called with --installed this may not be true, but it's okay
                # since we don't touch the @available Set in reload_installed
                available = false
                installed = true
              when "a"
                available = true
                installed = false
              when "r"
                available = true
                installed = true
              end

              pkg = RPMDbPackage.new(name, epoch, version, release, arch, provides, installed, available, repoid)
              @rpmdb << pkg
            end

            error = status.stderr

            if status.exitstatus != 0
              raise Chef::Exceptions::Package, "Yum failed - #{status.inspect} - returns: #{error}"
            else
              unless one_line
                Chef::Log.warn("Odd, no output from yum-dump.py. Please check " +
                               "your yum configuration.")
              end
            end

            # A reload method must be called before the cache is altered
            @next_refresh = :none
          end

          def reload
            @next_refresh = :all
          end

          def reload_installed
            @next_refresh = :installed
          end

          def reload_provides
            @next_refresh = :provides
          end

          def reset
            @rpmdb.clear
          end

          def reset_installed
            @rpmdb.clear_installed
          end

          # Querying the cache
          #

          # Check for package by name or name+arch
          def package_available?(package_name)
            refresh

            if @rpmdb.lookup(package_name)
              return true
            else
              if package_name =~ %r{^(.*)\.(.*)$}
                pkg_name = $1
                pkg_arch = $2

                if matches = @rpmdb.lookup(pkg_name)
                  matches.each do |m|
                    return true if m.arch == pkg_arch
                  end
                end
              end
            end

            return false
          end

          # Returns a array of packages satisfying an RPMDependency
          def packages_from_require(rpmdep)
            refresh
            @rpmdb.whatprovides(rpmdep)
          end

          # Check if a package-version.arch is available to install
          def version_available?(package_name, desired_version, arch=nil)
            version(package_name, arch, true, false) do |v|
              return true if desired_version == v
            end

            return false
          end

          # Return the source repository for a package-version.arch
          def package_repository(package_name, desired_version, arch=nil)
            package(package_name, arch, true, false) do |pkg|
              return pkg.repoid if desired_version == pkg.version.to_s
            end

            return nil
          end

          # Return the latest available version for a package.arch
          def available_version(package_name, arch=nil)
            version(package_name, arch, true, false)
          end
          alias :candidate_version :available_version

          # Return the currently installed version for a package.arch
          def installed_version(package_name, arch=nil)
            version(package_name, arch, false, true)
          end

          # Return an array of packages allowed to be installed multiple times, such as the kernel
          def allow_multi_install
            refresh
            @allow_multi_install
          end

          private

          def version(package_name, arch=nil, is_available=false, is_installed=false)
            package(package_name, arch, is_available, is_installed) do |pkg|
              return ( block_given? ? ( yield pkg.version.to_s ) : pkg.version.to_s )
            end

            return ( block_given? ? self : nil )
          end

          def package(package_name, arch=nil, is_available=false, is_installed=false)
            refresh
            packages = @rpmdb[package_name]
            return (block_given? ? self : nil) unless packages

            packages.each do |pkg|
              next if is_available && !@rpmdb.available?(pkg)
              next if is_installed && !@rpmdb.installed?(pkg)
              next if arch && pkg.arch != arch
              return (block_given? ? (yield pkg) : pkg)
            end
          end

          # Parse provides from yum-dump.py output
          def parse_provides(string)
            ret = []
            # ['atk = 1.12.2-1.fc6', 'libatk-1.0.so.0']
            string.split(", ").each do |seg|
              # 'atk = 1.12.2-1.fc6'
              if seg =~ %r{^'(.*)'$}
                ret << RPMProvide.parse($1)
              end
            end

            return ret
          end

        end # YumCache
      end
    end
  end
end
