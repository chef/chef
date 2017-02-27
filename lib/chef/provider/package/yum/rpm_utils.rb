
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software, Inc.
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

require "chef/provider/package"

class Chef
  class Provider
    class Package
      class Yum < Chef::Provider::Package
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

              if /^([\d]+):/.match(evr) # rubocop:disable Performance/RedundantMatch
                epoch = $1.to_i
                lead = $1.length + 1
              elsif evr[0].ord == ":".ord
                epoch = 0
                lead = 1
              end

              if /:?.*-(.*)$/.match(evr) # rubocop:disable Performance/RedundantMatch
                release = $1
                tail = evr.length - release.length - lead - 1

                if release.empty?
                  release = nil
                end
              end

              version = evr[lead, tail]
              if version.empty?
                version = nil
              end

              [ epoch, version, release ]
            end

            # verify
            def isalnum(x)
              isalpha(x) || isdigit(x)
            end

            def isalpha(x)
              v = x.ord
              (v >= 65 && v <= 90) || (v >= 97 && v <= 122)
            end

            def isdigit(x)
              v = x.ord
              v >= 48 && v <= 57
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

              while x_pos <= x_pos_max && y_pos <= y_pos_max
                # first we skip over anything non alphanumeric
                while (x_pos <= x_pos_max) && (isalnum(x[x_pos]) == false)
                  x_pos += 1 # +1 over pos_max if end of string
                end
                while (y_pos <= y_pos_max) && (isalnum(y[y_pos]) == false)
                  y_pos += 1
                end

                # if we hit the end of either we are done matching segments
                if (x_pos == x_pos_max + 1) || (y_pos == y_pos_max + 1)
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
                  while (x_seg_pos <= x_pos_max) && isdigit(x[x_seg_pos])
                    x_seg_pos += 1
                  end
                  # copy the segment but not the unmatched character that x_seg_pos will
                  # refer to
                  x_comp = x[x_pos, x_seg_pos - x_pos]

                  while (y_seg_pos <= y_pos_max) && isdigit(y[y_seg_pos])
                    y_seg_pos += 1
                  end
                  y_comp = y[y_pos, y_seg_pos - y_pos]
                else
                  # we are comparing strings
                  x_seg_is_num = false

                  while (x_seg_pos <= x_pos_max) && isalpha(x[x_seg_pos])
                    x_seg_pos += 1
                  end
                  x_comp = x[x_pos, x_seg_pos - x_pos]

                  while (y_seg_pos <= y_pos_max) && isalpha(y[y_seg_pos])
                    y_seg_pos += 1
                  end
                  y_comp = y[y_pos, y_seg_pos - y_pos]
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
              if (x_pos == x_pos_max + 1) && (y_pos == y_pos_max + 1)
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
              raise ArgumentError, "Expecting either 'epoch-version-release' or 'epoch, " \
                "version, release'"
            end
          end
          attr_reader :e, :v, :r
          alias epoch e
          alias version v
          alias release r

          def self.parse(*args)
            new(*args)
          end

          def <=>(other)
            compare_versions(other)
          end

          def compare(other)
            compare_versions(other, false)
          end

          def partial_compare(other)
            compare_versions(other, true)
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
          def compare_versions(y, partial = false)
            x = self

            # compare epoch
            if (x.e.nil? == false && x.e > 0) && y.e.nil?
              return 1
            elsif x.e.nil? && (y.e.nil? == false && y.e > 0)
              return -1
            elsif x.e.nil? == false && y.e.nil? == false
              if x.e < y.e
                return -1
              elsif x.e > y.e
                return 1
              end
            end

            # compare version
            if partial && (x.v.nil? || y.v.nil?)
              return 0
            elsif x.v.nil? == false && y.v.nil?
              return 1
            elsif x.v.nil? && y.v.nil? == false
              return -1
            elsif x.v.nil? == false && y.v.nil? == false
              cmp = RPMUtils.rpmvercmp(x.v, y.v)
              return cmp if cmp != 0
            end

            # compare release
            if partial && (x.r.nil? || y.r.nil?)
              return 0
            elsif x.r.nil? == false && y.r.nil?
              return 1
            elsif x.r.nil? && y.r.nil? == false
              return -1
            elsif x.r.nil? == false && y.r.nil? == false
              cmp = RPMUtils.rpmvercmp(x.r, y.r)
              return cmp
            end

            0
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
              @version = RPMVersion.new(e, v, r)
              @a = args[4]
              @provides = args[5]
            else
              raise ArgumentError, "Expecting either 'name, epoch-version-release, arch, provides' " \
                "or 'name, epoch, version, release, arch, provides'"
            end

            # We always have one, ourselves!
            if @provides.empty?
              @provides = [ RPMProvide.new(@n, @version.evr, :==) ]
            end
          end
          attr_reader :n, :a, :version, :provides
          alias name n
          alias arch a

          def <=>(other)
            compare(other)
          end

          def compare(y)
            x = self

            # easy! :)
            return 0 if x.nevra == y.nevra

            # compare name
            if x.n.nil? == false && y.n.nil?
              return 1
            elsif x.n.nil? && y.n.nil? == false
              return -1
            elsif x.n.nil? == false && y.n.nil? == false
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
            if x.a.nil? == false && y.a.nil?
              return 1
            elsif x.a.nil? && y.a.nil? == false
              return -1
            elsif x.a.nil? == false && y.a.nil? == false
              if x.a < y.a
                return -1
              elsif x.a > y.a
                return 1
              end
            end

            0
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
              @version = RPMVersion.new(e, v, r)
              @flag = args[4] || :==
            else
              raise ArgumentError, "Expecting either 'name, epoch-version-release, flag' or " \
                "'name, epoch, version, release, flag'"
            end
          end
          attr_reader :name, :version, :flag

          # Parses 2 forms:
          #
          # "mtr >= 2:0.71-3.0"
          # "mta"
          def self.parse(string)
            if /^(\S+)\s+(>|>=|=|==|<=|<)\s+(\S+)$/.match(string) # rubocop:disable Performance/RedundantMatch
              name = $1
              flag = if $2 == "="
                       :==
                     else
                       :"#{$2}"
                     end
              version = $3

              new(name, version, flag)
            else
              name = string
              new(name, nil, nil)
            end
          end

          # Test if another RPMDependency satisfies our requirements
          def satisfy?(y)
            unless y.is_a?(RPMDependency)
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
            if (sense < 0) && ((x.flag == :> || x.flag == :>=) || (y.flag == :<= || y.flag == :<))
              return true
            elsif (sense > 0) && ((x.flag == :< || x.flag == :<=) || (y.flag == :>= || y.flag == :>))
              return true
            elsif sense == 0 && (
              ((x.flag == :== || x.flag == :<= || x.flag == :>=) && (y.flag == :== || y.flag == :<= || y.flag == :>=)) ||
              (x.flag == :< && y.flag == :<) ||
              (x.flag == :> && y.flag == :>)
            )
              return true
            end

            false
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
            @rpms = {}
            # package nevra => RPMPackage for lookups
            @index = {}
            # provide name (aka feature) => [RPMPackage, RPMPackage] each providing this feature
            @provides = {}
            # RPMPackages listed as available
            @available = Set.new
            # RPMPackages listed as installed
            @installed = Set.new
          end

          def [](package_name)
            lookup(package_name)
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
              unless new_rpm.is_a?(RPMDbPackage)
                raise ArgumentError, "Expecting an RPMDbPackage object"
              end

              @rpms[new_rpm.n] ||= []

              # we may already have this one, like when the installed list is refreshed
              idx = @index[new_rpm.nevra]
              if idx
                # grab the existing package if it's not
                curr_rpm = idx
              else
                @rpms[new_rpm.n] << new_rpm

                new_rpm.provides.each do |provide|
                  @provides[provide.name] ||= []
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
            push(args)
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
          alias length size

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
            unless rpmdep.is_a?(RPMDependency)
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

            what
          end
        end

      end
    end
  end
end
