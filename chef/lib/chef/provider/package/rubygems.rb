#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2008, 2010 Opscode, Inc.
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

# Class methods on Gem are defined in rubygems
require 'rubygems'
require 'rubygems/specification'
require 'rubygems/version'
require 'rubygems/dependency'
require 'rubygems/spec_fetcher'
require 'rubygems/platform'
require 'rubygems/format'
require 'rubygems/dependency_installer'

class Chef
  class Provider
    class Package
      class Rubygems < Chef::Provider::Package
        class GemEnvironment

          ##
          # The paths where rubygems should search for installed gems
          # Implemented by subclasses.
          def gem_paths
            raise NotImplementedError
          end

          ##
          # A rubygems source index containing the list of gemspecs for all
          # available gems in the gem installation.
          # Implemented by subclasses
          # === Returns
          # Gem::SourceIndex
          def gem_source_index
            raise NotImplementedError
          end

          ##
          # Lists the installed versions of +gem_name+, constrained by the
          # version spec in +gem_dep+
          # === Arguments
          # Gem::Dependency   +gem_dep+ is a Gem::Dependency object, its version
          #                   specification constrains which gems are returned.
          # === Returns
          # [Gem::Specification]  an array of Gem::Specification objects
          def installed_versions(gem_dep)
            gem_source_index.search(gem_dep)
          end

          ##
          # Yields to the provided block with rubygems' source list set to the
          # list provided. Always resets the list when the block returns or
          # raises an exception.
          def with_gem_sources(*sources)
            sources.compact!
            original_sources = Gem.sources
            Gem.sources = sources unless sources.empty?
            yield
          ensure
            Gem.sources = original_sources
          end

          ##
          # Determines the candidate version for a gem from a .gem file on disk
          # and checks if it matches the version contraints in +gem_dependency+
          # === Returns
          # Gem::Version  a singular gem version object is returned if the gem
          #               is available
          # nil           returns nil if the gem on disk doesn't match the
          #               version constraints for +gem_dependency+
          def candidate_version_from_file(gem_dependency, source)
            spec = Gem::Format.from_file_by_path(source).spec
            if spec.satisfies_requirement?(gem_dependency)
              logger.debug {"found candidate gem version #{spec.version} from local gem package #{source}"}
              spec.version
            else
              # This is probably going to end badly...
              logger.warn { "The gem package #{source} does not satisfy the requirements #{gem_dependency.to_s}" }
              nil
            end
          end

          ##
          # Finds the newest version that satisfies the constraints of
          # +gem_dependency+. If a path to a file is given as a source, the
          # version is determined by parsing the gem's gemspec. Otherwise, the
          # version is determined from the cache or a round-trip to the server
          # as needed
          # === Returns
          # Gem::Version  a singular gem version object is returned if the gem
          #               is available
          # nil           returns nil if the gem could not be found
          def candidate_version_from_remote(gem_dependency, *sources)
            raise NotImplementedError
          end

          ##
          # Find the newest gem version available from Gem.sources that satisfies
          # the constraints of +gem_dependency+
          def find_newest_remote_version(gem_dependency, *sources)
            # DependencyInstaller sorts the results such that the last one is
            # always the one it considers best.
            spec_with_source = dependency_installer.find_gems_with_sources(gem_dependency).last
            spec = spec_with_source && spec_with_source[0]
            version = spec && spec_with_source[0].version
            if version
              logger.debug { "Found gem #{spec.name} version #{version} for platform #{spec.platform} from #{spec_with_source[1]}" }
              version
            else
              source_list = sources.compact.empty? ? "[#{Gem.sources.join(', ')}]" : "[#{sources.join(', ')}]"
              logger.debug { "Failed to find gem #{gem_dependency} from #{source_list}" }
              nil
            end
          end

          ##
          # Installs a gem via the rubygems ruby API.
          # === Options
          # :sources    rubygems servers to use
          # Other options are passed to Gem::DependencyInstaller.new
          def install(gem_dependency, options={})
            with_gem_sources(*options.delete(:sources)) do
              dependency_installer(options).install(gem_dependency)
            end
          end

          def dependency_installer(opts={})
            Gem::DependencyInstaller.new(opts)
          end

          private

          def logger
            Chef::Log.logger
          end

        end

        class CurrentGemEnvironment < GemEnvironment

          def gem_paths
            Gem.path
          end

          def gem_source_index
            Gem.source_index
          end

          def candidate_version_from_remote(gem_dependency, *sources)
            with_gem_sources(*sources) do
              find_newest_remote_version(gem_dependency, *sources)
            end
          end

        end

        class AlternateGemEnvironment < GemEnvironment
          JRUBY_PLATFORM = /(:?universal|x86_64|x86)\-java\-[0-9\.]+/

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

          def gem_source_index
            @source_index ||= Gem::SourceIndex.from_gems_in(*gem_paths.map { |p| p + '/specifications' })
          end

          ##
          # Attempt to detect the correct platform settings for the target gem
          # environment.
          #
          # In practice, this only makes a difference if different versions are
          # available depending on platform, and only if the target gem
          # environment has a radically different platform (i.e., jruby), so we
          # just try to detect jruby and fall back to the current platforms
          # (Gem.platforms) if we don't detect it.
          #
          # === Returns
          # [String|Gem::Platform] returns an array of Gem::Platform-compatible
          # objects, i.e., Strings that are valid for Gem::Platform or actual
          # Gem::Platform objects.
          def gem_platforms
            @gem_platforms ||= begin
              gem_environment = shell_out!("#{@gem_binary_location} env").stdout
              if jruby = gem_environment[JRUBY_PLATFORM]
                ['ruby', Gem::Platform.new(jruby)]
              else
                Gem.platforms
              end
            end
          end

          def with_gem_platforms(*alt_gem_platforms)
            alt_gem_platforms.flatten!
            original_gem_platforms = Gem.platforms
            Gem.platforms = alt_gem_platforms
            yield
          ensure
            Gem.platforms = original_gem_platforms
          end

          def candidate_version_from_remote(gem_dependency, *sources)
            with_gem_sources(*sources) do
              with_gem_platforms(*gem_platforms) do
                find_newest_remote_version(gem_dependency, *sources)
              end
            end
          end

        end

        attr_reader :gem_env

        def logger
          Chef::Log.logger
        end

        def initialize(new_resource, run_context=nil)
          super
          if new_resource.gem_binary
            @gem_env = AlternateGemEnvironment.new(new_resource.gem_binary)
          else
            @gem_env = CurrentGemEnvironment.new
          end
        end

        def gem_dependency
          Gem::Dependency.new(@new_resource.package_name, @new_resource.version)
        end

        def explicit_source_is_remote?
          return false if @new_resource.source.nil?
          URI.parse(@new_resource.source).absolute?
        end

        def current_version
          #raise 'todo'
          # If one or more matching versions are installed, the newest of them
          # is the current version
          if !matching_installed_versions.empty?
            gemspec = matching_installed_versions.last
            logger.debug { "Found installed gem #{gemspec.name} version #{gemspec.version} matching #{gem_dependency}"}
            gemspec
          # If no version matching the requirements exists, the latest installed
          # version is the current version.
          elsif !all_installed_versions.empty?
            gemspec = all_installed_versions.last
            logger.debug { "Newest installed version of gem #{gemspec.name} is #{gemspec.version}" }
            gemspec
          else
            logger.debug { "No installed version found for #{gem_dependency.to_s}"}
            nil
          end
        end

        def matching_installed_versions
          @matching_installed_versions ||= @gem_env.installed_versions(gem_dependency)
        end

        def all_installed_versions
          @all_installed_versions ||= begin
            @gem_env.installed_versions(Gem::Dependency.new(gem_dependency.name))
          end
        end

        def gem_sources
          @new_resource.source ? [@new_resource.source, 'http://rubygems.org'] : nil
        end

        def load_current_resource
          @current_resource = Chef::Resource::Package::GemPackage.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)
          @current_resource.version(current_version.version.to_s)
          @current_resource
        end

        def candidate_version
          @candidate_version ||= begin
            if target_version_already_installed?
              nil
            elsif explicit_source_is_remote?
              @gem_env.candidate_version_from_remote(gem_dependency, *gem_sources).to_s
            else
              @gem_env.candidate_version_from_file(gem_dependency, @new_resource.source).to_s
            end
          end
        end

        def target_version_already_installed?
          return false unless @current_resource && @current_resource.version
          return false if @current_resource.version.nil?
          # This works according to the behavior of the current implementation.
          # in the future it probably makes sense to revisit this, in particular
          # if ppl want to use action_upgrade with squiggly requirements
          # i.e., "~> 1.2.0"
          Gem::Requirement.new(@new_resource.version).satisfied_by?(Gem::Version.new(@current_resource.version))
        end

        # def action_install
        #   if @new_resource.version != nil && @new_resource.version != @current_resource.version
        #     install_version = @new_resource.version
        #   # If it's not installed at all, install it
        #   elsif @current_resource.version == nil
        #     install_version = candidate_version
        #   else
        #     return
        #   end
        #
        #   unless install_version
        #     raise(Chef::Exceptions::Package, "No version specified, and no candidate version available for #{@new_resource.package_name}")
        #   end
        #
        #   Chef::Log.info("Installing #{@new_resource} version #{install_version}")
        #
        #   status = install_package(@new_resource.package_name, install_version)
        #   if status
        #     @new_resource.updated = true
        #   end
        #
        # end

        def install_package(name, version)
          # If we install with a DependencyInstaller.new, this is equivalent to:
          # --no-rdoc --no-ri --no-test on the command line.
          # DependencyInstaller also offers the following options
          # :bin_dir, :development, :domain, :env_shebang, :force, :format_executable
          # :ignore_dependencies, :prerelease, :security_policy, :user_install,
          # :wrappers, :install_dir, :cache_dir
          #
          # So it seems that the sensible thing to do is:
          # 1. Use dependency installer by default
          # 2. shell out to install when a String of options is given (log an info about this.)
          # 3. use dependency installer + opts if a hash of options is given
          if explicit_source_is_remote? && @new_resource.gem_binary.nil?
            if @new_resource.options.nil?
              @gem_env.install(gem_dependency, :sources => gem_sources)
            elsif @new_resource.options.kind_of?(Hash)
              options = @new_resource.options
              options[:sources] = gem_sources
              @gem_env.install(gem_dependency, options)
            else
              install_via_gem_command
            end
          elsif @new_resource.gem_binary.nil?
            @gem_env.install(@new_resource.source)
          else
            install_via_gem_command
          end
          true
        end

        def install_via_gem_command
          src = @new_resource.source && "  --source=#{@new_resource.source} --source=http://rubygems.org"
          shell_out!("#{gem_binary_path} install #{name} -q --no-rdoc --no-ri -v \"#{version}\"#{src}#{opts}", :env=>nil)
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
