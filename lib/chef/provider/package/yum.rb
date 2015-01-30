#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/config'
require 'chef/provider/package'
require 'chef/mixin/command'
require 'chef/mixin/shell_out'
require 'chef/resource/package'
require 'singleton'
require 'chef/mixin/get_source_from_package'

class Chef
  class Provider
    class Package
      class Yum < Chef::Provider::Package

        provides :yum_package, os: "linux"

        class RPMUtils
          class << self

            # RPM::Version version_parse equivalent
            def version_parse(evr)
              return if evr.nil?

              epoch = nil
              # assume this is a version
              version = evr
              release = nil

              lead = 0
              tail = evr.size

              if evr =~ %r{^([\d]+):}
                epoch = $1.to_i
                lead = $1.length + 1
              elsif evr[0].ord == ":".ord
                epoch = 0
                lead = 1
              end

              if evr =~ %r{:?.*-(.*)$}
                release = $1
                tail = evr.length - release.length - lead - 1

                if release.empty?
                  release = nil
                end
              end

              version = evr[lead,tail]
              if version.empty?
                version = nil
              end

              [ epoch, version, release ]
            end

            # verify
            def isalnum(x)
              isalpha(x) or isdigit(x)
            end

            def isalpha(x)
              v = x.ord
              (v >= 65 and v <= 90) or (v >= 97 and v <= 122)
            end

            def isdigit(x)
              v = x.ord
              v >= 48 and v <= 57
            end

            # based on the reference spec in lib/rpmvercmp.c in rpm 4.9.0
            def rpmvercmp(x, y)
              # easy! :)
              return 0 if x == y

              if x.nil?
                x = ""
              end

              if y.nil?
                y = ""
              end

              # not so easy :(
              #
              # takes 2 strings like
              #
              # x = "1.20.b18.el5"
              # y = "1.20.b17.el5"
              #
              # breaks into purely alpha and numeric segments and compares them using
              # some rules
              #
              # * 10 > 1
              # * 1 > a
              # * z > a
              # * Z > A
              # * z > Z
              # * leading zeros are ignored
              # * separators (periods, commas) are ignored
              # * "1.20.b18.el5.extrastuff" > "1.20.b18.el5"

              x_pos = 0                # overall string element reference position
              x_pos_max = x.length - 1 # number of elements in string, starting from 0
              x_seg_pos = 0            # segment string element reference position
              x_comp = nil             # segment to compare

              y_pos = 0
              y_seg_pos = 0
              y_pos_max = y.length - 1
              y_comp = nil

              while (x_pos <= x_pos_max and y_pos <= y_pos_max)
                # first we skip over anything non alphanumeric
                while (x_pos <= x_pos_max) and (isalnum(x[x_pos]) == false)
                  x_pos += 1 # +1 over pos_max if end of string
                end
                while (y_pos <= y_pos_max) and (isalnum(y[y_pos]) == false)
                  y_pos += 1
                end

                # if we hit the end of either we are done matching segments
                if (x_pos == x_pos_max + 1) or (y_pos == y_pos_max + 1)
                  break
                end

                # we are now at the start of a alpha or numeric segment
                x_seg_pos = x_pos
                y_seg_pos = y_pos

                # grab segment so we can compare them
                if isdigit(x[x_seg_pos].ord)
                  x_seg_is_num = true

                  # already know it's a digit
                  x_seg_pos += 1

                  # gather up our digits
                  while (x_seg_pos <= x_pos_max) and isdigit(x[x_seg_pos])
                    x_seg_pos += 1
                  end
                  # copy the segment but not the unmatched character that x_seg_pos will
                  # refer to
                  x_comp = x[x_pos,x_seg_pos - x_pos]

                  while (y_seg_pos <= y_pos_max) and isdigit(y[y_seg_pos])
                    y_seg_pos += 1
                  end
                  y_comp = y[y_pos,y_seg_pos - y_pos]
                else
                  # we are comparing strings
                  x_seg_is_num = false

                  while (x_seg_pos <= x_pos_max) and isalpha(x[x_seg_pos])
                    x_seg_pos += 1
                  end
                  x_comp = x[x_pos,x_seg_pos - x_pos]

                  while (y_seg_pos <= y_pos_max) and isalpha(y[y_seg_pos])
                    y_seg_pos += 1
                  end
                  y_comp = y[y_pos,y_seg_pos - y_pos]
                end

                # if y_seg_pos didn't advance in the above loop it means the segments are
                # different types
                if y_pos == y_seg_pos
                  # numbers always win over letters
                  return x_seg_is_num ? 1 : -1
                end

                # move the ball forward before we mess with the segments
                x_pos += x_comp.length # +1 over pos_max if end of string
                y_pos += y_comp.length

                # we are comparing numbers - simply convert them
                if x_seg_is_num
                  x_comp = x_comp.to_i
                  y_comp = y_comp.to_i
                end

                # compares ints or strings
                # don't return if equal - try the next segment
                if x_comp > y_comp
                  return 1
                elsif x_comp < y_comp
                  return -1
                end

                # if we've reached here than the segments are the same - try again
              end

              # we must have reached the end of one or both of the strings and they
              # matched up until this point

              # segments matched completely but the segment separators were different -
              # rpm reference code treats these as equal.
              if (x_pos == x_pos_max + 1) and (y_pos == y_pos_max + 1)
                return 0
              end

              # the most unprocessed characters left wins
              if (x_pos_max - x_pos) > (y_pos_max - y_pos)
                return 1
              else
                return -1
              end
            end

          end # self
        end # RPMUtils

        class RPMVersion
          include Comparable

          def initialize(*args)
            if args.size == 1
              @e, @v, @r = RPMUtils.version_parse(args[0])
            elsif args.size == 3
              @e = args[0].to_i
              @v = args[1]
              @r = args[2]
            else
              raise ArgumentError, "Expecting either 'epoch-version-release' or 'epoch, " +
                                   "version, release'"
            end
          end
          attr_reader :e, :v, :r
          alias :epoch :e
          alias :version :v
          alias :release :r

          def self.parse(*args)
            self.new(*args)
          end

          def <=>(y)
            compare_versions(y)
          end

          def compare(y)
            compare_versions(y, false)
          end

          def partial_compare(y)
            compare_versions(y, true)
          end

          # RPM::Version rpm_version_to_s equivalent
          def to_s
            if @r.nil?
              @v
            else
              "#{@v}-#{@r}"
            end
          end

          def evr
            "#{@e}:#{@v}-#{@r}"
          end

          private

          # Rough RPM::Version rpm_version_cmp equivalent - except much slower :)
          #
          # partial lets epoch and version segment equality be good enough to return equal, eg:
          #
          # 2:1.2-1 == 2:1.2
          # 2:1.2-1 == 2:
          #
          def compare_versions(y, partial=false)
            x = self

            # compare epoch
            if (x.e.nil? == false and x.e > 0) and y.e.nil?
              return 1
            elsif x.e.nil? and (y.e.nil? == false and y.e > 0)
              return -1
            elsif x.e.nil? == false and y.e.nil? == false
              if x.e < y.e
                return -1
              elsif x.e > y.e
                return 1
              end
            end

            # compare version
            if partial and (x.v.nil? or y.v.nil?)
              return 0
            elsif x.v.nil? == false and y.v.nil?
              return 1
            elsif x.v.nil? and y.v.nil? == false
              return -1
            elsif x.v.nil? == false and y.v.nil? == false
              cmp = RPMUtils.rpmvercmp(x.v, y.v)
              return cmp if cmp != 0
            end

            # compare release
            if partial and (x.r.nil? or y.r.nil?)
              return 0
            elsif x.r.nil? == false and y.r.nil?
              return 1
            elsif x.r.nil? and y.r.nil? == false
              return -1
            elsif x.r.nil? == false and y.r.nil? == false
              cmp = RPMUtils.rpmvercmp(x.r, y.r)
              return cmp
            end

            return 0
          end
        end

        class RPMPackage
          include Comparable

          def initialize(*args)
            if args.size == 4
              @n = args[0]
              @version = RPMVersion.new(args[1])
              @a = args[2]
              @provides = args[3]
            elsif args.size == 6
              @n = args[0]
              e = args[1].to_i
              v = args[2]
              r = args[3]
              @version = RPMVersion.new(e,v,r)
              @a = args[4]
              @provides = args[5]
            else
              raise ArgumentError, "Expecting either 'name, epoch-version-release, arch, provides' " +
                                   "or 'name, epoch, version, release, arch, provides'"
            end

            # We always have one, ourselves!
            if @provides.empty?
              @provides = [ RPMProvide.new(@n, @version.evr, :==) ]
            end
          end
          attr_reader :n, :a, :version, :provides
          alias :name :n
          alias :arch :a

          def <=>(y)
            compare(y)
          end

          def compare(y)
            x = self

            # easy! :)
            return 0 if x.nevra == y.nevra

            # compare name
            if x.n.nil? == false and y.n.nil?
              return 1
            elsif x.n.nil? and y.n.nil? == false
              return -1
            elsif x.n.nil? == false and y.n.nil? == false
              if x.n < y.n
                return -1
              elsif x.n > y.n
                return 1
              end
            end

            # compare version
            if x.version > y.version
              return 1
            elsif x.version < y.version
              return -1
            end

            # compare arch
            if x.a.nil? == false and y.a.nil?
              return 1
            elsif x.a.nil? and y.a.nil? == false
              return -1
            elsif x.a.nil? == false and y.a.nil? == false
              if x.a < y.a
                return -1
              elsif x.a > y.a
                return 1
              end
            end

            return 0
          end

          def to_s
            nevra
          end

          def nevra
            "#{@n}-#{@version.evr}.#{@a}"
          end
        end

        # Simple implementation from rpm and ruby-rpm reference code
        class RPMDependency
          def initialize(*args)
            if args.size == 3
              @name = args[0]
              @version = RPMVersion.new(args[1])
              # Our requirement to other dependencies
              @flag = args[2] || :==
            elsif args.size == 5
              @name = args[0]
              e = args[1].to_i
              v = args[2]
              r = args[3]
              @version = RPMVersion.new(e,v,r)
              @flag = args[4] || :==
            else
              raise ArgumentError, "Expecting either 'name, epoch-version-release, flag' or " +
                                   "'name, epoch, version, release, flag'"
            end
          end
          attr_reader :name, :version, :flag

          # Parses 2 forms:
          #
          # "mtr >= 2:0.71-3.0"
          # "mta"
          def self.parse(string)
            if string =~ %r{^(\S+)\s+(>|>=|=|==|<=|<)\s+(\S+)$}
              name = $1
              if $2 == "="
                flag = :==
              else
                flag = :"#{$2}"
              end
              version = $3

              return self.new(name, version, flag)
            else
              name = string
              return self.new(name, nil, nil)
            end
          end

          # Test if another RPMDependency satisfies our requirements
          def satisfy?(y)
            unless y.kind_of?(RPMDependency)
              raise ArgumentError, "Expecting an RPMDependency object"
            end

            x = self

            # Easy!
            if x.name != y.name
              return false
            end

            # Partial compare
            #
            # eg: x.version 2.3 == y.version 2.3-1
            sense = x.version.partial_compare(y.version)

            # Thanks to rpmdsCompare() rpmds.c
            if sense < 0 and (x.flag == :> || x.flag == :>=) || (y.flag == :<= || y.flag == :<)
              return true
            elsif sense > 0 and (x.flag == :< || x.flag == :<=) || (y.flag == :>= || y.flag == :>)
              return true
            elsif sense == 0 and (
              ((x.flag == :== or x.flag == :<= or x.flag == :>=) and (y.flag == :== or y.flag == :<= or y.flag == :>=)) or
              (x.flag == :< and y.flag == :<) or
              (x.flag == :> and y.flag == :>)
            )
              return true
            end

            return false
          end
        end

        class RPMProvide < RPMDependency; end
        class RPMRequire < RPMDependency; end

        class RPMDbPackage < RPMPackage
          # <rpm parts>, installed, available
          def initialize(*args)
            @repoid = args.pop
            # state
            @available = args.pop
            @installed = args.pop
            super(*args)
          end
          attr_reader :repoid, :available, :installed
        end

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

        # Cache for our installed and available packages, pulled in from yum-dump.py
        class YumCache
          include Chef::Mixin::Command
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

            @extra_repo_control = nil

            # these are for subsequent runs if we are on an interval
            Chef::Client.when_run_starts do
              YumCache.instance.reload
            end
          end

          attr_reader :extra_repo_control

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

            if @extra_repo_control
              opts << " #{@extra_repo_control}"
            end

            opts << " --yum-lock-timeout #{Chef::Config[:yum_lock_timeout]}"

            one_line = false
            error = nil

            helper = ::File.join(::File.dirname(__FILE__), 'yum-dump.py')
            status = nil

            begin
              status = shell_out!("/usr/bin/python #{helper}#{opts}", :timeout => Chef::Config[:yum_timeout])
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
            rescue Mixlib::ShellOut::CommandTimeout => e
              Chef::Log.error("#{helper} exceeded timeout #{Chef::Config[:yum_timeout]}")
              raise(e)
            end

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

          def enable_extra_repo_control(arg)
            # Don't touch cache if it's the same repos as the last load
            unless @extra_repo_control == arg
              @extra_repo_control = arg
              reload
            end
          end

          def disable_extra_repo_control
            # Only force reload when set
            if @extra_repo_control
              @extra_repo_control = nil
              reload
            end
          end

          private

          def version(package_name, arch=nil, is_available=false, is_installed=false)
            package(package_name, arch, is_available, is_installed) do |pkg|
              if block_given?
                yield pkg.version.to_s
              else
                # first match is latest version
                return pkg.version.to_s
              end
            end

            if block_given?
              return self
            else
              return nil
            end
          end

          def package(package_name, arch=nil, is_available=false, is_installed=false)
            refresh
            packages = @rpmdb[package_name]
            if packages
              packages.each do |pkg|
                if is_available
                  next unless @rpmdb.available?(pkg)
                end
                if is_installed
                  next unless @rpmdb.installed?(pkg)
                end
                if arch
                  next unless pkg.arch == arch
                end

                if block_given?
                  yield pkg
                else
                  # first match is latest version
                  return pkg
                end
              end
            end

            if block_given?
              return self
            else
              return nil
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

        include Chef::Mixin::GetSourceFromPackage

        def initialize(new_resource, run_context)
          super

          @yum = YumCache.instance
        end

        # Extra attributes
        #

        def arch
          if @new_resource.respond_to?("arch")
            @new_resource.arch
          else
            nil
          end
        end

        def flush_cache
          if @new_resource.respond_to?("flush_cache")
            @new_resource.flush_cache
          else
            { :before => false, :after => false }
          end
        end

        def allow_downgrade
          if @new_resource.respond_to?("allow_downgrade")
            @new_resource.allow_downgrade
          else
            false
          end
        end

        # Helpers
        #

        def yum_arch
          arch ? ".#{arch}" : nil
        end

        def yum_command(command)
          status, stdout, stderr = output_of_command(command, {:timeout => Chef::Config[:yum_timeout]})

          # This is fun: rpm can encounter errors in the %post/%postun scripts which aren't
          # considered fatal - meaning the rpm is still successfully installed. These issue
          # cause yum to emit a non fatal warning but still exit(1). As there's currently no
          # way to suppress this behavior and an exit(1) will break a Chef run we make an
          # effort to trap these and re-run the same install command - it will either fail a
          # second time or succeed.
          #
          # A cleaner solution would have to be done in python and better hook into
          # yum/rpm to handle exceptions as we see fit.
          if status.exitstatus == 1
            stdout.each_line do |l|
              # rpm-4.4.2.3 lib/psm.c line 2182
              if l =~ %r{^error: %(post|postun)\(.*\) scriptlet failed, exit status \d+$}
                Chef::Log.warn("#{@new_resource} caught non-fatal scriptlet issue: \"#{l}\". Can't trust yum exit status " +
                               "so running install again to verify.")
                status, stdout, stderr = output_of_command(command, {:timeout => Chef::Config[:yum_timeout]})
                break
              end
            end
          end

          if status.exitstatus > 0
            command_output = "STDOUT: #{stdout}"
            command_output << "STDERR: #{stderr}"
            handle_command_failures(status, command_output, {})
          end
        end

        # Standard Provider methods for Parent
        #

        def load_current_resource
          if flush_cache[:before]
            @yum.reload
          end

          if @new_resource.options
            repo_control = []
            @new_resource.options.split.each do |opt|
              if opt =~ %r{--(enable|disable)repo=.+}
                repo_control << opt
              end
            end

            if repo_control.size > 0
              @yum.enable_extra_repo_control(repo_control.join(" "))
            else
              @yum.disable_extra_repo_control
            end
          else
            @yum.disable_extra_repo_control
          end

          # At this point package_name could be:
          #
          # 1) a package name, eg: "foo"
          # 2) a package name.arch, eg: "foo.i386"
          # 3) or a dependency, eg: "foo >= 1.1"

          # Check if we have name or name+arch which has a priority over a dependency
          package_name_array.each do |n|
            unless @yum.package_available?(n)
              # If they aren't in the installed packages they could be a dependency
              dep = parse_dependency(n)
              if dep
                if @new_resource.package_name.is_a?(Array)
                  @new_resource.package_name(package_name_array + [dep])
                else
                  @new_resource.package_name(dep)
                end
              end
            end
          end

          # Don't overwrite an existing arch
          unless arch
            parse_arch
          end

          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)

          if @new_resource.source
            unless ::File.exists?(@new_resource.source)
              raise Chef::Exceptions::Package, "Package #{@new_resource.name} not found: #{@new_resource.source}"
            end

            Chef::Log.debug("#{@new_resource} checking rpm status")
            shell_out!("rpm -qp --queryformat '%{NAME} %{VERSION}-%{RELEASE}\n' #{@new_resource.source}", :timeout => Chef::Config[:yum_timeout]).stdout.each_line do |line|
              case line
              when /([\w\d_.-]+)\s([\w\d_.-]+)/
                @current_resource.package_name($1)
                @new_resource.version($2)
              end
            end
          end

          if @new_resource.version
            new_resource = "#{@new_resource.package_name}-#{@new_resource.version}#{yum_arch}"
          else
            new_resource = "#{@new_resource.package_name}#{yum_arch}"
          end

          Chef::Log.debug("#{@new_resource} checking yum info for #{new_resource}")

          installed_version = []
          @candidate_version = []
          package_name_array.each do |pkg|
            installed_version << @yum.installed_version(pkg, arch)
            @candidate_version << @yum.candidate_version(pkg, arch)
          end
          if installed_version.size == 1
            @current_resource.version(installed_version[0])
            @candidate_version = @candidate_version[0]
          else
            @current_resource.version(installed_version)
          end

          Chef::Log.debug("#{@new_resource} installed version: #{installed_version || "(none)"} candidate version: " +
                          "#{@candidate_version || "(none)"}")

          @current_resource
        end

        def install_remote_package(name, version)
          # Work around yum not exiting with an error if a package doesn't exist
          # for CHEF-2062
          all_avail = as_array(name).zip(as_array(version)).any? do |n, v|
            @yum.version_available?(n, v, arch)
          end
          method = log_method = nil
          methods = []
          if all_avail
            # More Yum fun:
            #
            # yum install of an old name+version will exit(1)
            # yum install of an old name+version+arch will exit(0) for some reason
            #
            # Some packages can be installed multiple times like the kernel
            as_array(name).zip(as_array(version)).each do |n, v|
              method = "install"
              log_method = "installing"
              idx = package_name_array.index(n)
              unless @yum.allow_multi_install.include?(n)
                if RPMVersion.parse(current_version_array[idx]) > RPMVersion.parse(v)
                  # We allow downgrading only in the evenit of single-package
                  # rules where the user explicitly allowed it
                  if allow_downgrade
                    method = "downgrade"
                    log_method = "downgrading"
                  else
                    # we bail like yum when the package is older
                    raise Chef::Exceptions::Package, "Installed package #{name}-#{@current_resource.version} is newer " +
                                                     "than candidate package #{n}-#{v}"
                  end
                end
              end
              # methods don't count for packages we won't be touching
              next if RPMVersion.parse(current_version_array[idx]) == RPMVersion.parse(v)
              methods << method
            end

            # We could split this up into two commands if we wanted to, but
            # for now, just don't support this.
            if methods.uniq.length > 1
              raise Chef::Exceptions::Package, "Multipackage rule #{name} has a mix of upgrade and downgrade packages. Cannot proceed."
            end

            repos = []
            pkg_string_bits = []
            index = 0
            as_array(name).zip(as_array(version)).each do |n, v|
              s = ''
              unless v == current_version_array[index]
                s = "#{n}-#{v}#{yum_arch}"
                repo = @yum.package_repository(n, v, arch)
                repos << "#{s} from #{repo} repository"
                pkg_string_bits << s
              end
              index += 1
            end
            pkg_string = pkg_string_bits.join(' ')
            Chef::Log.info("#{@new_resource} #{log_method} #{repos.join(' ')}")
            yum_command("yum -d0 -e0 -y#{expand_options(@new_resource.options)} #{method} #{pkg_string}")
          else
            raise Chef::Exceptions::Package, "Version #{version} of #{name} not found. Did you specify both version " +
                                             "and release? (version-release, e.g. 1.84-10.fc6)"
          end
        end

        def install_package(name, version)
          if @new_resource.source
            yum_command("yum -d0 -e0 -y#{expand_options(@new_resource.options)} localinstall #{@new_resource.source}")
          else
            install_remote_package(name, version)
          end

          if flush_cache[:after]
            @yum.reload
          else
            @yum.reload_installed
          end
        end

        # Keep upgrades from trying to install an older candidate version. Can happen when a new
        # version is installed then removed from a repository, now the older available version
        # shows up as a viable install candidate.
        #
        # Can be done in upgrade_package but an upgraded from->to log message slips out
        #
        # Hacky - better overall solution? Custom compare in Package provider?
        def action_upgrade
          # Could be uninstalled or have no candidate
          if @current_resource.version.nil? || !candidate_version_array.any?
            super
          elsif candidate_version_array.zip(current_version_array).any? do |c, i|
                  RPMVersion.parse(c) > RPMVersion.parse(i)
                end
            super
          else
            Chef::Log.debug("#{@new_resource} is at the latest version - nothing to do")
          end
        end

        def upgrade_package(name, version)
          install_package(name, version)
        end

        def remove_package(name, version)
          if version
            remove_str = as_array(name).zip(as_array(version)).map do |x|
              "#{x.join('-')}#{yum_arch}"
            end.join(' ')
          else
            remove_str = as_array(name).map { |n| "#{n}#{yum_arch}" }.join(' ')
          end
          yum_command("yum -d0 -e0 -y#{expand_options(@new_resource.options)} remove #{remove_str}")

          if flush_cache[:after]
            @yum.reload
          else
            @yum.reload_installed
          end
        end

        def purge_package(name, version)
          remove_package(name, version)
        end

        private

        def parse_arch
          # Allow for foo.x86_64 style package_name like yum uses in it's output
          #
          if @new_resource.package_name =~ %r{^(.*)\.(.*)$}
            new_package_name = $1
            new_arch = $2
            # foo.i386 and foo.beta1 are both valid package names or expressions of an arch.
            # Ensure we don't have an existing package matching package_name, then ensure we at
            # least have a match for the new_package+new_arch before we overwrite. If neither
            # then fall through to standard package handling.
            if (@yum.installed_version(@new_resource.package_name).nil? and @yum.candidate_version(@new_resource.package_name).nil?) and
                 (@yum.installed_version(new_package_name, new_arch) or @yum.candidate_version(new_package_name, new_arch))
               @new_resource.package_name(new_package_name)
               @new_resource.arch(new_arch)
            end
          end
        end

        # If we don't have the package we could have been passed a 'whatprovides' feature
        #
        # eg: yum install "perl(Config)"
        #     yum install "mtr = 2:0.71-3.1"
        #     yum install "mtr > 2:0.71"
        #
        # We support resolving these out of the Provides data imported from yum-dump.py and
        # matching them up with an actual package so the standard resource handling can apply.
        #
        # There is currently no support for filename matching.
        def parse_dependency(name)
          # Transform the package_name into a requirement
          yum_require = RPMRequire.parse(name)
          # and gather all the packages that have a Provides feature satisfying the requirement.
          # It could be multiple be we can only manage one
          packages = @yum.packages_from_require(yum_require)

          if packages.empty?
            # Don't bother if we are just ensuring a package is removed - we don't need Provides data
            actions = Array(@new_resource.action)
            unless actions.size == 1 and (actions[0] == :remove || actions[0] == :purge)
              Chef::Log.debug("#{@new_resource} couldn't match #{@new_resource.package_name} in " +
                            "installed Provides, loading available Provides - this may take a moment")
              @yum.reload_provides
              packages = @yum.packages_from_require(yum_require)
            end
          end

          unless packages.empty?
            new_package_name = packages.first.name
            Chef::Log.debug("#{@new_resource} no package found for #{@new_resource.package_name} " +
                            "but matched Provides for #{new_package_name}")

            # Ensure it's not the same package under a different architecture
            unique_names = []
            packages.each do |pkg|
              unique_names << "#{pkg.name}-#{pkg.version.evr}"
            end
            unique_names.uniq!

            if unique_names.size > 1
              Chef::Log.warn("#{@new_resource} matched multiple Provides for #{@new_resource.package_name} " +
                             "but we can only use the first match: #{new_package_name}. Please use a more " +
                             "specific version.")
            end

            new_package_name
          end
        end

      end
    end
  end
end
