class Chef
  class Provider
    class Package
      class Yum
        # Simple storage for RPMPackage objects - keeps them unique and sorted
        class RPMDb
          def initialize
            # package name => [ RPMPackage, RPMPackage ] of different versions
            @rpms = Hash.new
            # package nevra => RPMPackage for lookups
            @index = Hash.new
            # provide name (aka feature) => [RPMPackage, RPMPackage] each providing this feature
            @provides = Hash.new
            # RPMPackages listed as available
            @available = Set.new
            # RPMPackages listed as installed
            @installed = Set.new
          end

          def [](package_name)
            self.lookup(package_name)
          end

          # Lookup package_name and return a descending array of package objects
          def lookup(package_name)
            pkgs = @rpms[package_name]
            if pkgs
              return pkgs.sort.reverse
            else
              return nil
            end
          end

          def lookup_provides(provide_name)
            @provides[provide_name]
          end

          # Using the package name as a key, and nevra for an index, keep a unique list of packages.
          # The available/installed state can be overwritten for existing packages.
          def push(*args)
            args.flatten.each do |new_rpm|
              unless new_rpm.kind_of?(RPMDbPackage)
                raise ArgumentError, "Expecting an RPMDbPackage object"
              end

              @rpms[new_rpm.n] ||= Array.new

              # we may already have this one, like when the installed list is refreshed
              idx = @index[new_rpm.nevra]
              if idx
                # grab the existing package if it's not
                curr_rpm = idx
              else
                @rpms[new_rpm.n] << new_rpm

                new_rpm.provides.each do |provide|
                  @provides[provide.name] ||= Array.new
                  @provides[provide.name] << new_rpm
                end

                curr_rpm = new_rpm
              end

              # Track the nevra -> RPMPackage association to avoid having to compare versions
              # with @rpms[new_rpm.n] on the next round
              @index[new_rpm.nevra] = curr_rpm

              # these are overwritten for existing packages
              if new_rpm.available
                @available << curr_rpm
              end
              if new_rpm.installed
                @installed << curr_rpm
              end
            end
          end

          def <<(*args)
            self.push(args)
          end

          def clear
            @rpms.clear
            @index.clear
            @provides.clear
            clear_available
            clear_installed
          end

          def clear_available
            @available.clear
          end

          def clear_installed
            @installed.clear
          end

          def size
            @rpms.size
          end
          alias :length :size

          def available_size
            @available.size
          end

          def installed_size
            @installed.size
          end

          def available?(package)
            @available.include?(package)
          end

          def installed?(package)
            @installed.include?(package)
          end

          def whatprovides(rpmdep)
            unless rpmdep.kind_of?(RPMDependency)
              raise ArgumentError, "Expecting an RPMDependency object"
            end

            what = []

            packages = lookup_provides(rpmdep.name)
            if packages
              packages.each do |pkg|
                pkg.provides.each do |provide|
                  if provide.satisfy?(rpmdep)
                    what << pkg
                  end
                end
              end
            end

            return what
          end
        end
      end
    end
  end
end
