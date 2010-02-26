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
      
        class YumCache
          include Chef::Mixin::Command
          include Singleton

          def initialize
            load_data
          end

          def stale?
            interval = Chef::Config[:interval].to_f

            # run once mode
            if interval == 0
              return false
            elsif (Time.now - @updated_at) > interval
              return true
            end

            false
          end
            
          def refresh
            if @data.empty?
              reload
            elsif stale?
               reload
            end
          end

          def load_data
            @data = Hash.new
            error = String.new

            helper = ::File.join(::File.dirname(__FILE__), 'yum-dump.py')
            status = popen4("python #{helper}", :waitlast => true) do |pid, stdin, stdout, stderr|
              stdout.each do |line|
                line.chomp!
                name, type, epoch, version, release, arch = line.split(',')
                type_sym = type.to_sym
                if !@data.has_key?(name)
                  @data[name] = Hash.new
                end
                @data[name][type_sym] = { :epoch => epoch, :version => version,
                                          :release => release, :arch => arch }
              end
              
              error = stderr.readlines
            end

            unless status.exitstatus == 0
              raise Chef::Exceptions::Package, "yum failed - #{status.inspect} - returns: #{error}"
            end

            @updated_at = Time.now
          end
          alias :reload :load_data

          def version(package_name, type)
            if (x = @data[package_name])
              if (y = x[type])
                return "#{y[:version]}-#{y[:release]}"
              end
            end

            nil
          end

          def installed_version(package_name)
            version(package_name, :installed)
          end

          def candidate_version(package_name)
            version(package_name, :available)
          end
         
          def flush
            @data.clear
          end
        end

        def initialize(node, new_resource, collection=nil, definitions=nil, cookbook_loader=nil)
          @yum = YumCache.instance
          super(node, new_resource, collection, definitions, cookbook_loader)
        end
      
        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)
        
          if @new_resource.source
            unless ::File.exists?(@new_resource.source)
              raise Chef::Exceptions::Package, "Package #{@new_resource.name} not found: #{@new_resource.source}"
            end

            Chef::Log.debug("Checking rpm status for  #{@new_resource.package_name}")
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

          Chef::Log.debug("Checking yum info for #{@new_resource.package_name}")
    
          @yum.refresh

          installed_version = @yum.installed_version(@new_resource.package_name)
          @candidate_version = @yum.candidate_version(@new_resource.package_name)
          
          @current_resource.version(installed_version)
          if candidate_version
            @candidate_version = candidate_version
          else
            @candidate_version = installed_version
          end
        
          @current_resource
        end

        def install_package(name, version)
          if @new_resource.source 
            run_command_with_systems_locale(
              :command => "yum -d0 -e0 -y localinstall #{@new_resource.source}"
            )
          else
            run_command_with_systems_locale(
              :command => "yum -d0 -e0 -y install #{name}-#{version}"
            )
          end
          @yum.flush
        end
      
        def upgrade_package(name, version)
          # If we're not given a version, running update is the correct
          # option. If we are, then running install_package is right.
          unless version
            run_command_with_systems_locale(
              :command => "yum -d0 -e0 -y update #{name}"
            )   
            @yum.flush
          else
            install_package(name, version)
          end
        end

        def remove_package(name, version)
          if version
            run_command_with_systems_locale(
             :command => "yum -d0 -e0 -y remove #{name}-#{version}"
            )
          else
            run_command_with_systems_locale(
             :command => "yum -d0 -e0 -y remove #{name}"
            )
          end
            
          @yum.flush
        end
      
        def purge_package(name, version)
          remove_package(name, version)
        end
      
      end
    end
  end
end
