#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

autoload :URI, "uri"
require_relative "../package"
require_relative "../../resource/package"
require_relative "../../mixin/get_source_from_package"
require_relative "../../mixin/which"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

# Class methods on Gem are defined in rubygems
autoload :Gem, "rubygems"
# Ruby 1.9's gem_prelude can interact poorly with loading the full rubygems
# explicitly like this. Make sure rubygems/specification is always last in this
# list
Gem.autoload :Version, "rubygems/version"
Gem.autoload :Dependency, "rubygems/dependency"
Gem.autoload :SpecFetcher, "rubygems/spec_fetcher"
Gem.autoload :Platform, "rubygems/platform"
Gem.autoload :Package, "rubygems/package"
Gem.autoload :DependencyInstaller, "rubygems/dependency_installer"
Gem.autoload :Uninstaller, "rubygems/uninstaller"
Gem.autoload :Specification, "rubygems/specification"

class Chef
  class Provider
    class Package
      class Rubygems < Chef::Provider::Package
        class GemEnvironment
          DEFAULT_UNINSTALLER_OPTS = { ignore: true, executables: true }.freeze

          def initialize(*args)
            super
            # HACK: trigger gem config load early. Otherwise it can get lazy
            # loaded during operations where we've set Gem.sources to an
            # alternate value and overwrite it with the defaults.
            Gem.configuration
          end

          # The paths where rubygems should search for installed gems.
          # Implemented by subclasses.
          def gem_paths
            raise NotImplementedError
          end

          # A rubygems source index containing the list of gemspecs for all
          # available gems in the gem installation.
          # Implemented by subclasses
          #
          # @return [Gem::SourceIndex]
          #
          def gem_source_index
            raise NotImplementedError
          end

          # A rubygems specification object containing the list of gemspecs for all
          # available gems in the gem installation.
          # Implemented by subclasses
          #
          # @return [Gem::Specification]
          #
          def gem_specification
            raise NotImplementedError
          end

          def rubygems_version
            raise NotImplementedError
          end

          # Lists the installed versions of +gem_name+, constrained by the
          # version spec in +gem_dep+
          #
          # @param gem_dep [Gem::Dependency] the version specification that constrains
          #   which gems are used.
          # @return [Array<Gem::Specification>]  an array of Gem::Specification objects
          #
          def installed_versions(gem_dep)
            rubygems_version = Gem::Version.new(Gem::VERSION)
            if rubygems_version >= Gem::Version.new("2.7")
              # In newer Rubygems, bundler is now a "default gem" which means
              # even with AlternateGemEnvironment when you try to get the
              # installed versions, you get the one from Chef's Ruby's default
              # gems. This workaround ignores default gems entirely so we see
              # only the installed gems.
              stubs = gem_specification.send(:installed_stubs, gem_specification.dirs, "#{gem_dep.name}-*.gemspec")
              # Filter down to only to only stubs we actually want. The name
              # filter is needed in case of things like `foo-*.gemspec` also
              # matching a gem named `foo-bar`.
              stubs.select! { |stub| stub.name == gem_dep.name && gem_dep.requirement.satisfied_by?(stub.version) }
              # This isn't sorting before returning because the only code that
              # uses this method calls `max_by` so it doesn't need to be sorted.
              stubs
            else # >= rubygems 1.8 behavior
              gem_specification.find_all_by_name(gem_dep.name, gem_dep.requirement)
            end
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
          # Extracts the gemspec from a (on-disk) gem package.
          # === Returns
          # Gem::Specification
          #
          #--
          # Compatibility note: Rubygems 1.x uses Gem::Format, 2.0 moved this
          # code into Gem::Package.
          def spec_from_file(file)
            if defined?(Gem::Format) && Gem::Package.respond_to?(:open)
              Gem::Format.from_file_by_path(file).spec
            else
              Gem::Package.new(file).spec
            end
          end

          ##
          # Determines the candidate version for a gem from a .gem file on disk
          # and checks if it matches the version constraints in +gem_dependency+
          # === Returns
          # Gem::Version  a singular gem version object is returned if the gem
          #               is available
          # nil           returns nil if the gem on disk doesn't match the
          #               version constraints for +gem_dependency+
          def candidate_version_from_file(gem_dependency, source)
            spec = spec_from_file(source)
            if spec.satisfies_requirement?(gem_dependency)
              logger.trace { "found candidate gem version #{spec.version} from local gem package #{source}" }
              spec.version
            else
              # This is probably going to end badly...
              logger.warn { "gem package #{source} does not satisfy the requirements #{gem_dependency}" }
              nil
            end
          end

          ##
          # Finds the newest version that satisfies the constraints of
          # +gem_dependency+. The version is determined from the cache or a
          # round-trip to the server as needed. The architecture and gem
          # sources will be set before making the query.
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
            spec, source =
              if Chef::Config[:rubygems_cache_enabled]
                # This code caches every gem on rubygems.org and uses lots of RAM
                available_gems = dependency_installer.find_gems_with_sources(gem_dependency)
                available_gems.pick_best!
                best_gem = available_gems.set.first
                best_gem && [best_gem.spec, best_gem.source]
              else
                # Use the API that 'gem install' calls which does not pull down the rubygems universe
                begin
                  rs = dependency_installer.resolve_dependencies gem_dependency.name, gem_dependency.requirement
                  rs.specs.find { |s| s.name == gem_dependency.name }
                  # ruby-3.0.0 versions of rubygems-3.x throws NoMethodError when the dep is not found
                rescue Gem::UnsatisfiableDependencyError, NoMethodError
                  nil
                end
              end

            version = spec && spec.version
            if version
              logger.trace { "found gem #{spec.name} version #{version} for platform #{spec.platform} from #{source}" }
              version
            else
              source_list = sources.compact.empty? ? "[#{Gem.sources.to_a.join(", ")}]" : "[#{sources.join(", ")}]"
              logger.warn { "failed to find gem #{gem_dependency} from #{source_list}" }
              nil
            end
          end

          ##
          # Installs a gem via the rubygems ruby API.
          # === Options
          # :sources    rubygems servers to use
          # Other options are passed to Gem::DependencyInstaller.new
          def install(gem_dependency, options = {})
            with_gem_sources(*options.delete(:sources)) do
              with_correct_verbosity do
                dependency_installer(options).install(gem_dependency)
              end
            end
          end

          ##
          # Uninstall the gem +gem_name+ via the rubygems ruby API. If
          # +gem_version+ is provided, only that version will be uninstalled.
          # Otherwise, all versions are uninstalled.
          # === Options
          # Options are passed to Gem::Uninstaller.new
          def uninstall(gem_name, gem_version = nil, opts = {})
            gem_version ? opts[:version] = gem_version : opts[:all] = true
            with_correct_verbosity do
              uninstaller(gem_name, opts).uninstall
            end
          end

          ##
          # Set rubygems' user interaction to ConsoleUI or SilentUI depending
          # on our current debug level
          def with_correct_verbosity
            Gem::DefaultUserInteraction.ui = logger.trace? ? Gem::ConsoleUI.new : Gem::SilentUI.new
            yield
          end

          def dependency_installer(opts = {})
            Gem::DependencyInstaller.new(opts)
          end

          def uninstaller(gem_name, opts = {})
            Gem::Uninstaller.new(gem_name, DEFAULT_UNINSTALLER_OPTS.merge(opts))
          end

          private

          def logger
            Chef::Log.with_child({ subsystem: "gem_installer_environment" })
          end

        end

        class CurrentGemEnvironment < GemEnvironment

          def gem_paths
            Gem.path
          end

          def gem_source_index
            Gem.source_index
          end

          def gem_specification
            Gem::Specification
          end

          def rubygems_version
            Gem::VERSION
          end

          def candidate_version_from_remote(gem_dependency, *sources)
            with_gem_sources(*sources) do
              find_newest_remote_version(gem_dependency, *sources)
            end
          end

        end

        class AlternateGemEnvironment < GemEnvironment
          JRUBY_PLATFORM = /(:?universal|x86_64|x86)\-java\-[0-9\.]+/.freeze

          def self.gempath_cache
            @gempath_cache ||= {}
          end

          def self.platform_cache
            @platform_cache ||= {}
          end

          include Chef::Mixin::ShellOut

          attr_reader :gem_binary_location

          def initialize(gem_binary_location)
            @gem_binary_location = gem_binary_location
          end

          def rubygems_version
            @rubygems_version ||= shell_out!("#{@gem_binary_location} --version").stdout.chomp
          end

          def gem_paths
            if self.class.gempath_cache.key?(@gem_binary_location)
              self.class.gempath_cache[@gem_binary_location]
            else
              # shellout! is a fork/exec which won't work on windows
              shell_style_paths = shell_out!("#{@gem_binary_location} env gempath").stdout
              # on windows, the path separator is (usually? always?) semicolon
              paths = shell_style_paths.split(::File::PATH_SEPARATOR).map(&:strip)
              self.class.gempath_cache[@gem_binary_location] = paths
            end
          end

          def gem_source_index
            @source_index ||= Gem::SourceIndex.from_gems_in(*gem_paths.map { |p| p + "/specifications" })
          end

          def gem_specification
            # Only once, dirs calls a reset
            unless @specification
              Gem::Specification.dirs = gem_paths
              @specification = Gem::Specification
            end
            @specification
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
            if self.class.platform_cache.key?(@gem_binary_location)
              self.class.platform_cache[@gem_binary_location]
            else
              gem_environment = shell_out!("#{@gem_binary_location} env").stdout
              self.class.platform_cache[@gem_binary_location] = if jruby = gem_environment[JRUBY_PLATFORM]
                                                                  ["ruby", Gem::Platform.new(jruby)]
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
        attr_reader :cleanup_gem_env

        provides :chef_gem
        provides :gem_package

        include Chef::Mixin::GetSourceFromPackage
        include Chef::Mixin::Which

        def initialize(new_resource, run_context = nil)
          super
          @cleanup_gem_env = true
          if new_resource.gem_binary
            if new_resource.options && new_resource.options.is_a?(Hash)
              msg =  "options cannot be given as a hash when using an explicit gem_binary\n"
              msg << "in #{new_resource} from #{new_resource.source_line}"
              raise ArgumentError, msg
            end
            @gem_env = AlternateGemEnvironment.new(new_resource.gem_binary)
            logger.trace("#{new_resource} using gem '#{new_resource.gem_binary}'")
          elsif is_omnibus? && (!new_resource.instance_of? Chef::Resource::ChefGem)
            # Opscode Omnibus - The ruby that ships inside omnibus is only used for Chef
            # Default to installing somewhere more functional
            if new_resource.options && new_resource.options.is_a?(Hash)
              msg = [
                "Gem options must be passed to gem_package as a string instead of a hash when",
                "using this installation of #{ChefUtils::Dist::Infra::PRODUCT} because it runs with its own packaged Ruby. A hash",
                "may only be used when installing a gem to the same Ruby installation that #{ChefUtils::Dist::Infra::PRODUCT} is",
                "running under. See https://docs.chef.io/resources/gem_package/ for more information.",
                "Error raised at #{new_resource} from #{new_resource.source_line}",
              ].join("\n")
              raise ArgumentError, msg
            end
            gem_location = find_gem_by_path
            new_resource.gem_binary gem_location
            @gem_env = AlternateGemEnvironment.new(gem_location)
            logger.trace("#{new_resource} using gem '#{gem_location}'")
          else
            @gem_env = CurrentGemEnvironment.new
            @cleanup_gem_env = false
            logger.trace("#{new_resource} using gem from running ruby environment")
          end
        end

        def is_omnibus?
          if %r{/(opscode|chef|chefdk)/embedded/bin}.match?(RbConfig::CONFIG["bindir"])
            logger.trace("#{new_resource} detected omnibus installation in #{RbConfig::CONFIG["bindir"]}")
            # Omnibus installs to a static path because of linking on unix, find it.
            true
          elsif RbConfig::CONFIG["bindir"].sub(/^\w:/, "") == "/opscode/chef/embedded/bin"
            logger.trace("#{new_resource} detected omnibus installation in #{RbConfig::CONFIG["bindir"]}")
            # windows, with the drive letter removed
            true
          else
            false
          end
        end

        def find_gem_by_path
          which("gem", extra_path: RbConfig::CONFIG["bindir"])
        end

        def gem_dependency
          Gem::Dependency.new(new_resource.package_name, new_resource.version)
        end

        def source_is_remote?
          return true if new_resource.source.nil?
          return true if new_resource.source.is_a?(Array)

          scheme = URI.parse(new_resource.source).scheme
          # URI.parse gets confused by MS Windows paths with forward slashes.
          scheme = nil if /^[a-z]$/.match?(scheme)
          %w{http https}.include?(scheme)
        rescue URI::InvalidURIError
          logger.trace("#{new_resource} failed to parse source '#{new_resource.source}' as a URI, assuming a local path")
          false
        end

        def current_version
          # If one or more matching versions are installed, the newest of them
          # is the current version
          if !matching_installed_versions.empty?
            gemspec = matching_installed_versions.max_by(&:version)
            logger.trace { "#{new_resource} found installed gem #{gemspec.name} version #{gemspec.version} matching #{gem_dependency}" }
            gemspec
            # If no version matching the requirements exists, the latest installed
            # version is the current version.
          elsif !all_installed_versions.empty?
            gemspec = all_installed_versions.max_by(&:version)
            logger.trace { "#{new_resource} newest installed version of gem #{gemspec.name} is #{gemspec.version}" }
            gemspec
          else
            logger.trace { "#{new_resource} no installed version found for #{gem_dependency}" }
            nil
          end
        end

        def matching_installed_versions
          @matching_installed_versions ||= @gem_env.installed_versions(gem_dependency)
        end

        def all_installed_versions
          @all_installed_versions ||= begin
                                        @gem_env.installed_versions(Gem::Dependency.new(gem_dependency.name, ">= 0"))
                                      end
        end

        ##
        # If `include_default_source` is nil, return true if the global
        # `rubygems_url` was set or if `clear_sources` and `source` on the
        # resource are not set.
        # If `include_default_source` is not nil, it has been set explicitly on
        # the resource and that value should be used.
        def include_default_source?
          if new_resource.include_default_source.nil?
            !!Chef::Config[:rubygems_url] || !(new_resource.source || new_resource.clear_sources)
          else
            new_resource.include_default_source
          end
        end

        def gem_sources
          srcs = [ new_resource.source ]
          srcs << (Chef::Config[:rubygems_url] || "https://rubygems.org") if include_default_source?
          srcs.flatten.compact
        end

        def load_current_resource
          @current_resource = Chef::Resource::Package::GemPackage.new(new_resource.name)
          current_resource.package_name(new_resource.package_name)
          if current_spec = current_version
            current_resource.version(current_spec.version.to_s)
          end
          current_resource
        end

        def cleanup_after_converge
          if @cleanup_gem_env
            logger.trace { "#{new_resource} resetting gem environment to default" }
            Gem.clear_paths
          end
        end

        def candidate_version
          @candidate_version ||= begin
                                  if source_is_remote?
                                    @gem_env.candidate_version_from_remote(gem_dependency, *gem_sources).to_s
                                  else
                                    @gem_env.candidate_version_from_file(gem_dependency, new_resource.source).to_s
                                  end
                                end
        end

        def version_requirement_satisfied?(current_version, new_version)
          return false unless current_version && new_version

          Gem::Requirement.new(new_version).satisfied_by?(Gem::Version.new(current_version))
        end

        ##
        # Installs the gem, using either the gems API or shelling out to `gem`
        # according to the following criteria:
        # 1. Use gems API (Gem::DependencyInstaller) by default
        # 2. shell out to `gem install` when a String of options is given
        # 3. use gems API with options if a hash of options is given
        def install_package(name, version)
          if source_is_remote? && new_resource.gem_binary.nil?
            if new_resource.options.nil?
              @gem_env.install(gem_dependency, sources: gem_sources)
            elsif new_resource.options.is_a?(Hash)
              options = new_resource.options
              options[:sources] = gem_sources
              @gem_env.install(gem_dependency, options)
            else
              install_via_gem_command(name, version)
            end
          elsif new_resource.gem_binary.nil?
            @gem_env.install(new_resource.source)
          else
            install_via_gem_command(name, version)
          end
          true
        end

        def gem_binary_path
          new_resource.gem_binary || "gem"
        end

        ##
        # If `clear_sources` is nil, clearing sources is implied if a `source`
        # was added or if the global rubygems URL is set. If `clear_sources`
        # is not nil, it has been set explicitly on the resource and its value
        # should be used.
        def clear_sources?
          if new_resource.clear_sources.nil?
            !!(new_resource.source || Chef::Config[:rubygems_url])
          else
            new_resource.clear_sources
          end
        end

        def install_via_gem_command(name, version)
          src = []
          if new_resource.source.is_a?(String) && new_resource.source =~ /\.gem$/i
            name = new_resource.source
          else
            src << "--clear-sources" if clear_sources?
            src += gem_sources.map { |s| "--source=#{s}" }
          end
          src_str = src.empty? ? "" : " #{src.join(" ")}"
          if !version.nil? && !version.empty?
            shell_out!("#{gem_binary_path} install #{name} -q #{rdoc_string} -v \"#{version}\"#{src_str}#{opts}", env: nil)
          else
            shell_out!("#{gem_binary_path} install \"#{name}\" -q #{rdoc_string} #{src_str}#{opts}", env: nil)
          end
        end

        def upgrade_package(name, version)
          install_package(name, version)
        end

        def remove_package(name, version)
          if new_resource.gem_binary.nil?
            if new_resource.options.nil?
              @gem_env.uninstall(name, version)
            elsif new_resource.options.is_a?(Hash)
              @gem_env.uninstall(name, version, new_resource.options)
            else
              uninstall_via_gem_command(name, version)
            end
          else
            uninstall_via_gem_command(name, version)
          end
        end

        def uninstall_via_gem_command(name, version)
          if version
            shell_out!("#{gem_binary_path} uninstall #{name} -q -x -I -v \"#{version}\"#{opts}", env: nil)
          else
            shell_out!("#{gem_binary_path} uninstall #{name} -q -x -I -a#{opts}", env: nil)
          end
        end

        def purge_package(name, version)
          remove_package(name, version)
        end

        private

        def rdoc_string
          if needs_nodocument?
            "--no-document"
          else
            "--no-rdoc --no-ri"
          end
        end

        def needs_nodocument?
          Gem::Requirement.new(">= 3.0.0.beta1").satisfied_by?(Gem::Version.new(gem_env.rubygems_version))
        end

        def opts
          expand_options(new_resource.options)
        end

      end
    end
  end
end
