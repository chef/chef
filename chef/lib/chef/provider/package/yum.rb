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

require 'chef/provider/package'
require 'chef/mixin/command'
require 'chef/resource/package'
require 'singleton'

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

        class RPMPackage
          include Comparable

          def initialize(name, evr, arch)
            @n = name 
            @e, @v, @r = RPMUtils.version_parse(evr)
            @a = arch
          end
          attr_reader :n, :e, :v, :r, :a
          alias :name :n
          alias :epoch :e
          alias :version :v
          alias :release :r
          alias :arch :a

          # RPM::Version rpm_version_cmp equivalent - except much slower :)
          def <=>(y)
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
            if x.v.nil? == false and y.v.nil?
              return 1
            elsif x.v.nil? and y.v.nil? == false
              return -1
            elsif x.v.nil? == false and y.v.nil? == false
              cmp = RPMUtils.rpmvercmp(x.v, y.v)
              return cmp if cmp != 0
            end

            # compare release 
            if x.r.nil? == false and y.r.nil?
              return 1
            elsif x.r.nil? and y.r.nil? == false
              return -1
            elsif x.r.nil? == false and y.r.nil? == false
              cmp = RPMUtils.rpmvercmp(x.r, y.r)
            end

            return cmp
          end
         
          # RPM::Version rpm_version_to_s equivalent
          def to_s 
            if @r.nil?
              @v
            else
              "#{@v}-#{@r}"
            end
          end

          def nevra
            "#{@n}-#{@e}:#{@v}-#{@r}.#{@a}"
          end

        end

        class YumCache
          include Chef::Mixin::Command
          include Singleton

          def initialize
            load_data

            # these are for subsequent runs if we are on an interval
            Chef::Client.when_run_starts do |run_status|
              YumCache.instance.load_data
            end
            Chef::Client.when_run_completes_successfully do |run_status|
              YumCache.instance.flush
            end
          end

          def load_data(cache=false)
            @data = Hash.new
            error = String.new
            one_line = false

            if cache
              opts="-C"
            else
              opts=""
            end

            helper = ::File.join(::File.dirname(__FILE__), 'yum-dump.py')
            status = popen4("/usr/bin/python #{helper}", :waitlast => true) do |pid, stdin, stdout, stderr|
              stdout.each do |line|
                one_line = true

                line.chomp!
                parts = line.split
                unless parts.size == 6
                  Chef::Log.warn("Problem parsing line '#{line}' from yum-dump.py! " +
                                 "Please check your yum configuration.")
                  next
                end
                name, epoch, version, release, arch, t = parts

                case t
                when "a"
                  type = :available
                when "i"
                  type = :installed
                end
                if !@data.has_key?(name)
                  @data[name] = Hash.new
                end
                if !@data[name].has_key?(type)
                  @data[name][type] = Hash.new
                end
                @data[name][type][arch] = { :epoch => epoch, :version => version,
                                            :release => release }
              end
              
              error = stderr.readlines
            end


            if status.exitstatus != 0
              raise Chef::Exceptions::Package, "yum failed - #{status.inspect} - returns: #{error}"
            else
              unless one_line
                Chef::Log.warn("Odd, no output from yum-dump.py. Please check " +
                               "your yum configuration.")
              end
            end
          end

          # reload is called after yum has been run. At this point the 
          # available/installed lists have already been updated so we can rely
          # on cache.
          def reload
            load_data(true)
          end

          def version(package_name, type, arch)
            if (x = @data[package_name])
              if (y = x[type])
                if arch
                  if (z = y[arch])
                    return "#{z[:version]}-#{z[:release]}"
                  end
                else
                  # no arch specified - take the first match
                  z = y.to_a[0][1]
                  return "#{z[:version]}-#{z[:release]}"
                end
              end
            end

            nil
          end

          def version_available?(package_name, desired_version, arch)
            if (package_data = @data[package_name])
              if (available_versions = package_data[:available])
                if arch
                  # arch gets passed like ".x86_64"
                  matching_versions = [ available_versions[arch.sub(/^./, '')]]
                else
                  matching_versions = available_versions.values
                end

                if matching_versions.nil?
                  if arch.empty?
                    arch_msg = ""
                  else
                    arch_msg = "with arch #{arch.sub(/^./, '')} "
                  end

                  raise ArgumentError, "#{package_name}: Found no available versions #{arch_msg}to match"
                end

                # Expect [ { :version => "ver", :release => "rel" }, { :version => "ver", :release => "rel" }, { :version => "ver", :release => "rel" } ] ???
                matching_versions.each do |ver|
                  Chef::Log.debug("#{@new_resource} trying to match #{desired_version} to version #{ver[:version]} and release #{ver[:release]}")
                  if (desired_version == "#{ver[:version]}-#{ver[:release]}")
                    return true
                  end
                end
              end
            end

            nil
          end

          def installed_version(package_name, arch)
            version(package_name, :installed, arch)
          end

          def candidate_version(package_name, arch)
            version(package_name, :available, arch)
          end

          def flush
            @data.clear
          end
        end

        def initialize(new_resource, run_context)
          super
          @yum = YumCache.instance
        end

        def arch
          if @new_resource.respond_to?("arch")
            @new_resource.arch 
          else
            nil
          end
        end

        def yum_arch
          arch ? ".#{arch}" : nil
        end

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)

          if @new_resource.source
            unless ::File.exists?(@new_resource.source)
              raise Chef::Exceptions::Package, "Package #{@new_resource.name} not found: #{@new_resource.source}"
            end

            Chef::Log.debug("#{@new_resource} checking rpm status")
            status = popen4("rpm -qp --queryformat '%{NAME} %{VERSION}-%{RELEASE}\n' #{@new_resource.source}") do |pid, stdin, stdout, stderr|
              stdout.each do |line|
                case line
                when /([\w\d_.-]+)\s([\w\d_.-]+)/
                  @current_resource.package_name($1)
                  @new_resource.version($2)
                end
              end
            end
          end

          Chef::Log.debug("#{@new_resource} checking yum info for #{@new_resource.package_name}#{yum_arch}")

          installed_version = @yum.installed_version(@new_resource.package_name, arch)
          @candidate_version = @yum.candidate_version(@new_resource.package_name, arch)

          @current_resource.version(installed_version)
          if candidate_version
            @candidate_version = candidate_version
          else
            @candidate_version = installed_version
          end
          Chef::Log.debug("#{@new_resource} installed version: #{installed_version} candidate version: #{candidate_version}")

          @current_resource
        end

        def install_package(name, version)
          if @new_resource.source 
            run_command_with_systems_locale(
              :command => "yum -d0 -e0 -y #{@new_resource.options} localinstall #{@new_resource.source}"
            )
          else
            # Work around yum not exiting with an error if a package doesn't exist for CHEF-2062
            if @yum.version_available?(name, version, yum_arch)
              run_command_with_systems_locale(
                :command => "yum -d0 -e0 -y #{@new_resource.options} install #{name}-#{version}#{yum_arch}"
              )
            else
              raise ArgumentError, "#{@new_resource.name}: Version #{version} of #{name} not found. Did you specify both version and release? (version-release, e.g. 1.84-10.fc6)"
            end
          end
          @yum.reload
        end

        def upgrade_package(name, version)
          # If we're not given a version, running update is the correct
          # option. If we are, then running install_package is right.
          unless version
            run_command_with_systems_locale(
              :command => "yum -d0 -e0 -y #{@new_resource.options} update #{name}#{yum_arch}"
            )
            @yum.reload
          else
            install_package(name, version)
          end
        end

        def remove_package(name, version)
          if version
            run_command_with_systems_locale(
             :command => "yum -d0 -e0 -y #{@new_resource.options} remove #{name}-#{version}#{yum_arch}"
            )
          else
            run_command_with_systems_locale(
             :command => "yum -d0 -e0 -y #{@new_resource.options} remove #{name}#{yum_arch}"
            )
          end
          @yum.reload
        end

        def purge_package(name, version)
          remove_package(name, version)
        end

      end
    end
  end
end
