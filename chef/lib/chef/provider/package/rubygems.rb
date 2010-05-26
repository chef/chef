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

require 'rubygems/specification'

class Chef
  class Provider
    class Package
      class Rubygems < Chef::Provider::Package
        class CurrentGemEnvironment

          def gem_paths
            Gem.path
          end

          def installed_versions(gem_name, version_spec=nil)
            gem_source_index.search(Gem::Dependency.new(gem_name, version_spec)).map { |g| g.version }
          end

          def gem_source_index
            Gem.source_index
          end
          
        end

        class AlternateGemEnvironment
          include Chef::Mixin::ShellOut

          attr_reader :gem_binary_location

          def initialize(gem_binary_location)
            @gem_binary_location = gem_binary_location
          end

          def gem_paths
            @gempaths ||= begin
              # shellout! is a fork/exec which won't work on windows
              shell_style_paths = shell_out!("#{@gem_binary_location} env gempath").stdout
              # on windows, the path separator is (usually? always?) semicolon
              shell_style_paths.split(::File::PATH_SEPARATOR).map { |path| path.strip }
            end
          end

          # TODO: de-duplicate
          def installed_versions(gem_name, version_spec=nil)
            gem_source_index.search(Gem::Dependency.new(gem_name, version_spec)).map { |g| g.version }
          end

          def gem_source_index
            @source_index ||= Gem::SourceIndex.from_gems_in(*gem_paths.map { |p| p + '/specifications' })
          end

        end

        attr_reader :gem_implementation

        def initialize(new_resource, run_context=nil)
          super
          if new_resource.gem_binary
            @gem_implementation = AlternateGemEnvironment.new(new_resource.gem_binary)
          else
            @gem_implementation = CurrentGemEnvironment.new
          end
        end

        def gem_list_parse(line)
          installed_versions = Array.new
          if md = line.match(/^#{@new_resource.package_name} \((.+?)(?: [^\)\.]+)?\)$/)
            md.captures.first.split(/, /)
          else
            nil
          end
        end

        # def gem_binary_path
        #   path = @new_resource.gem_binary
        #   path ? path : 'gem'
        # end

        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)
          @current_resource.version(nil)

          ## Find out if the gem is installed and what the version is
          pending
          
          # First, we need to look up whether we have the local gem installed or not
          # status = popen4("#{gem_binary_path} list --local #{@new_resource.package_name}") do |pid, stdin, stdout, stderr|
          #   stdout.each_line do |line|
          #     next unless installed_versions = gem_list_parse(line)
          #     # If the version we are asking for is installed, make that our current
          #     # version.  Otherwise, go ahead and use the highest one, which
          #     # happens to come first in the array.
          #     if installed_versions.detect { |v| v == @new_resource.version }
          #       Chef::Log.debug("#{@new_resource.package_name} at version #{@new_resource.version}")
          #       @current_resource.version(@new_resource.version)
          #     else
          #       iv = installed_versions.first
          #       Chef::Log.debug("#{@new_resource.package_name} at version #{iv}")
          #       @current_resource.version(iv)
          #     end
          #   end
          # end

          # unless status.exitstatus == 0
          #   raise Chef::Exceptions::Package, "#{gem_binary_path} list --local failed - #{status.inspect}!"
          # end

          @current_resource
        end

        def candidate_version
          return @candidate_version if @candidate_version

          status = popen4("#{gem_binary_path} list --remote #{@new_resource.package_name}#{' --source=' + @new_resource.source if @new_resource.source}") do |pid, stdin, stdout, stderr|
            stdout.each_line do |line|
              next unless installed_versions = gem_list_parse(line)
              Chef::Log.debug("candidate_version: remote rubygem(s) available: #{installed_versions.inspect}")

              unless installed_versions.empty?
                Chef::Log.debug("candidate_version: setting install candidate version to #{installed_versions.first}")
                @candidate_version = installed_versions.first
              end
            end

          end

          unless status.exitstatus == 0
            raise Chef::Exceptions::Package, "#{gem_binary_path} list --remote failed - #{status.inspect}!"
          end
          @candidate_version
        end

        def install_package(name, version)
          src = nil
          if @new_resource.source
            src = "  --source=#{@new_resource.source} --source=http://rubygems.org"
          end
          run_command_with_systems_locale(
            :command => "#{gem_binary_path} install #{name} -q --no-rdoc --no-ri -v \"#{version}\"#{src}#{opts}"
          )
        end

        def upgrade_package(name, version)
          install_package(name, version)
        end

        def remove_package(name, version)
          if version
            run_command_with_systems_locale(
              :command => "#{gem_binary_path} uninstall #{name} -q -v \"#{version}\""
            )
          else
            run_command_with_systems_locale(
              :command => "#{gem_binary_path} uninstall #{name} -q -a"
            )
          end
        end

        def purge_package(name, version)
          remove_package(name, version)
        end

        private

        def opts
          expand_options(@new_resource.options)
        end

      end
    end
  end
end
