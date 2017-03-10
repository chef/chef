require "rubygems"
require "bundler"
require "shellwords"
require "set"

module GemfileUtil
  #
  # Adds `override: true`, which allows your statement to override any other
  # gem statement about the same gem in the Gemfile.
  #
  def gem(name, *args)
    options = args[-1].is_a?(Hash) ? args[-1] : {}

    # Unless we're finished with everything, ignore gems that are being overridden
    unless overridden_gems == :finished
      # If it's a path or override gem, it overrides whatever else is there.
      if options[:path] || options[:override]
        options.delete(:override)
        warn_if_replacing(name, overridden_gems[name], args)
        overridden_gems[name] = args
        return

      # If there's an override gem, and we're *not* an override gem, don't do anything
      elsif overridden_gems[name]
        warn_if_replacing(name, args, overridden_gems[name])
        return
      end
    end

    # Otherwise, add the gem normally
    super
  rescue
    puts $!.backtrace
    raise
  end

  def overridden_gems
    @overridden_gems ||= {}
  end

  #
  # Just before we finish the Gemfile, finish up the override gems
  #
  def to_definition(*args)
    complete_overrides
    super
  end

  def complete_overrides
    to_override = overridden_gems
    unless to_override == :finished
      @overridden_gems = :finished
      to_override.each do |name, args|
        gem name, *args
      end
    end
  end

  #
  # Include all gems in the locked gemfile.
  #
  # @param gemfile_path Path to the Gemfile to load (relative to your Gemfile)
  # @param lockfile_path Path to the Gemfile to load (relative to your Gemfile).
  #          Defaults to <gemfile_path>.lock.
  # @param groups A list of groups to include (whitelist). If not passed (or set
  #          to nil), all gems will be selected.
  # @param without_groups A list of groups to ignore. Gems will be excluded from
  #          the results if all groups they belong to are ignored. This matches
  #          bundler's `without` behavior.
  # @param gems A list of gems to include above and beyond the given groups.
  #          Gems in this list must be explicitly included in the Gemfile
  #          with a `gem "gem_name", ...` line or they will be silently
  #          ignored.
  # @param copy_groups Whether to copy the groups over from the old lockfile to
  #          the new. Use this when the new lockfile has the same convention for
  #          groups as the old. Defaults to `false`.
  #
  def include_locked_gemfile(gemfile_path, lockfile_path = "#{gemfile_path}.lock", groups: nil, without_groups: nil, gems: [], copy_groups: false)
    # Parse the desired lockfile
    gemfile_path = Pathname.new(gemfile_path).expand_path(Bundler.default_gemfile.dirname).realpath
    lockfile_path = Pathname.new(lockfile_path).expand_path(Bundler.default_gemfile.dirname).realpath

    # Calculate relative_to
    relative_to = Bundler.default_gemfile.dirname.realpath

    # Call out to create-override-gemfile to read the Gemfile+Gemfile.lock (bundler does not work well if you do two things in one process)
    create_override_gemfile_bin = File.expand_path("../bin/create-override-gemfile", __FILE__)
    arguments = [
      "--gemfile", gemfile_path,
      "--lockfile", lockfile_path,
      "--override"
    ]
    arguments += [ "--relative-to", relative_to ] if relative_to != "."
    arguments += Array(groups).flat_map { |group| [ "--group", group ] }
    arguments += Array(without_groups).flat_map { |without| [ "--without", without ] }
    arguments += Array(gems).flat_map { |name| [ "--gem", name ] }
    arguments << "--copy-groups" if copy_groups
    cmd = Shellwords.join([ Gem.ruby, "-S", create_override_gemfile_bin, *arguments ])
    output = nil
    Bundler.ui.info("> #{cmd}")
    Bundler.with_clean_env do
      output = `#{cmd}`
    end
    instance_eval(output, cmd, 1)
  end

  #
  # Include all gems in the locked gemfile.
  #
  # @param current_gemfile The Gemfile you are currently loading (`self`).
  # @param gemfile_path Path to the Gemfile to load (relative to your Gemfile)
  # @param lockfile_path Path to the Gemfile to load (relative to your Gemfile).
  #          Defaults to <gemfile_path>.lock.
  # @param groups A list of groups to include (whitelist). If not passed (or set
  #          to nil), all gems will be selected.
  # @param without_groups A list of groups to ignore. Gems will be excluded from
  #          the results if all groups they belong to are ignored. This matches
  #          bundler's `without` behavior.
  # @param gems A list of gems to include above and beyond the given groups.
  #          Gems in this list must be explicitly included in the Gemfile
  #          with a `gem "gem_name", ...` line or they will be silently
  #          ignored.
  # @param copy_groups Whether to copy the groups over from the old lockfile to
  #          the new. Use this when the new lockfile has the same convention for
  #          groups as the old. Defaults to `false`.
  #
  def self.include_locked_gemfile(current_gemfile, gemfile_path, lockfile_path = "#{gemfile_path}.lock", groups: nil, without_groups: nil, gems: [], copy_groups: false)
    current_gemfile.instance_eval do
      extend GemfileUtil
      include_locked_gemfile(gemfile_path, lockfile_path, groups: groups, without_groups: without_groups, gems: gems, copy_groups: copy_groups)
    end
  end

  def warn_if_replacing(name, old_args, new_args)
    return if !old_args || !new_args
    if args_to_dep(name, *old_args) =~ args_to_dep(name, *new_args)
      Bundler.ui.debug "Replaced Gemfile dependency #{name} (#{old_args}) with (#{new_args})"
    else
      Bundler.ui.warn "Replaced Gemfile dependency #{name} (#{old_args}) with (#{new_args})"
    end
  end

  def args_to_dep(name, *version, **options)
    version = [">= 0"] if version.empty?
    Bundler::Dependency.new(name, version, options)
  end

  #
  # Reads a bundle, including a gemfile and lockfile.
  #
  # Does no validation, does not update the lockfile or its gems in any way.
  #
  class Bundle
    #
    # Parse the given gemfile/lockfile pair.
    #
    # @return [Bundle] The parsed bundle.
    #
    def self.parse(gemfile_path, lockfile_path = "#{gemfile_path}.lock")
      result = new(gemfile_path, lockfile_path)
      result.gems
      result
    end

    #
    # Create a new Bundle to parse the given gemfile/lockfile pair.
    #
    def initialize(gemfile_path, lockfile_path = "#{gemfile_path}.lock")
      @gemfile_path = gemfile_path
      @lockfile_path = lockfile_path
    end

    #
    # The path to the Gemfile
    #
    attr_reader :gemfile_path

    #
    # The path to the Lockfile
    #
    attr_reader :lockfile_path

    #
    # The list of gems.
    #
    # @return [Hash<String, Hash>] The resulting gems, where key = gem_name, and the
    #           hash has:
    #           - version: version of the gem.
    #           - source info (:source/:git/:ref/:path) from the lockfile
    #           - dependencies: A list of gem names this gem has a runtime
    #             dependency on. Dependencies are transitive: if A depends on B,
    #             and B depends on C, then A has C in its :dependencies list.
    #           - development_dependencies: - A list of gem names this gem has a
    #             development dependency on. Dependencies are transitive: if A
    #             depends on B, and B depends on C, then A has C in its
    #             :development_dependencies list. development dependencies *include*
    #             runtime dependencies.
    #           - groups: The list of groups (symbols) this gem is in. Groups
    #             are transitive: if A has a runtime dependency on B, and A is
    #             in group X, then B is also in group X.
    #           - declared_groups: The list of groups (symbols) this gem was
    #             declared in the Gemfile.
    #
    def gems
      @gems ||= begin
        gems = locks.dup
        gems.each do |name, g|
          if gem_declarations.has_key?(name)
            g[:declared_groups] = gem_declarations[name][:groups]
          else
            g[:declared_groups] = []
          end
          g[:groups] = g[:declared_groups].dup
        end
        # Transitivize groups (since dependencies are already transitive, this is easy)
        gems.each do |name, g|
          g[:dependencies].each do |dep|
            gems[dep][:groups] |= gems[name][:declared_groups].dup
          end
        end
        gems
      end
    end

    #
    # Get the gems (and their deps) in the given group.
    #
    # @param groups A list of groups to include (whitelist). If not passed (or set
    #          to nil), all gems will be selected.
    # @param without_groups A list of groups to ignore. Gems will be excluded from
    #          the results if all groups they belong to are ignored.
    #          This matches bundler's `without` behavior.
    # @param gems A list of gems to include regardless of what groups are included.
    #
    # @return Hash[String, Hash] The resulting gems, where key = gem_name, and the
    #           hash has:
    #           - version: version of the gem.
    #           - source info (:source/:git/:ref/:path) from the lockfile
    #           - dependencies: A list of gem names this gem has a runtime
    #             dependency on. Dependencies are transitive: if A depends on B,
    #             and B depends on C, then A has C in its :dependencies list.
    #           - development_dependencies: - A list of gem names this gem has a
    #             development dependency on. Dependencies are transitive: if A
    #             depends on B, and B depends on C, then A has C in its
    #             :development_dependencies list. development dependencies
    #             *include* runtime dependencies.
    #           - groups: The list of groups (symbols) this gem is in. Groups
    #             are transitive: if A has a runtime dependency on B, and A is
    #             in group X, then B is also in group X.
    #           - declared_groups: The list of groups (symbols) this gem was
    #             declared in the Gemfile.
    #
    def select_gems(groups: nil, without_groups: nil)
      # First, select the gems that match
      result = {}
      gems.each do |name, g|
        dep_groups = g[:declared_groups] - [ :only_a_runtime_dependency_of_other_gems ]
        dep_groups &= groups if groups
        dep_groups -= without_groups if without_groups
        if dep_groups.any?
          result[name] ||= g
          g[:dependencies].each do |dep|
            result[dep] ||= gems[dep]
          end
        end
      end
      result
    end

    #
    # Get all locks from the given lockfile.
    #
    # @return Hash[String, Hash] The resulting gems, where key = gem_name, and the
    #           hash has:
    #           - version: version of the gem.
    #           - source info (:source/:git/:ref/:path)
    #           - dependencies: A list of gem names this gem has a runtime
    #             dependency on. Dependencies are transitive: if A depends on B,
    #             and B depends on C, then A has C in its :dependencies list.
    #           - development_dependencies: - A list of gem names this gem has a
    #             development dependency on. Dependencies are transitive: if A
    #             depends on B, and B depends on C, then A has C in its
    #             :development_dependencies list. development dependencies *include*
    #             runtime dependencies.
    #
    def locks
      @locks ||= begin
        # Grab all the specs from the lockfile
        locks = {}
        parsed_lockfile = Bundler::LockfileParser.new(IO.read(lockfile_path))
        parsed_lockfile.specs.each do |spec|
          # Never include bundler, it can't be bundled and doesn't put itself in
          # the lockfile correctly anyway
          next if spec.name == "bundler"
          # Only the platform-specific locks for now (TODO make it possible to emit all locks)
          next if spec.platform && spec.platform != Gem::Platform::RUBY
          lock = lock_source_metadata(spec)
          lock[:version] = spec.version.to_s
          runtime = spec.dependencies.select { |dep| dep.type == :runtime }
          lock[:dependencies] = Set.new(runtime.map { |dep| dep.name })
          lock[:development_dependencies] = Set.new(spec.dependencies.map { |dep| dep.name })
          lock[:dependencies].delete("bundler")
          lock[:development_dependencies].delete("bundler")
          locks[spec.name] = lock
        end

        # Transitivize the deps.
        locks.each do |name, lock|
          # Not all deps were brought over (platform-specific ones) so weed them out
          lock[:dependencies] &= locks.keys
          lock[:development_dependencies] &= locks.keys

          lock[:dependencies] = transitive_dependencies(locks, name, :dependencies)
          lock[:development_dependencies] = transitive_dependencies(locks, name, :development_dependencies)
        end

        locks
      end
    end

    #
    # Get all desired gems, sans dependencies, from the gemfile.
    #
    # @param gemfile Path to the Gemfile to load
    #
    # @return Hash<String, Hash> An array of hashes where key = gem name and value
    #           has :groups (an array of symbols representing the groups the gem
    #           is in). :groups are not transitive, since we don't know the
    #           dependency tree yet.
    #
    def gem_declarations
      @gem_declarations ||= begin
        Bundler.with_clean_env do
          # Set BUNDLE_GEMFILE to the new gemfile temporarily so all bundler's things work
          # This works around some issues in bundler 1.11.2.
          ENV["BUNDLE_GEMFILE"] = gemfile_path

          parsed_gemfile = Bundler::Dsl.new
          parsed_gemfile.eval_gemfile(gemfile_path)
          parsed_gemfile.complete_overrides if parsed_gemfile.respond_to?(:complete_overrides)

          result = {}
          parsed_gemfile.dependencies.each do |dep|
            groups = dep.groups.empty? ? [:default] : dep.groups
            result[dep.name] = { groups: groups, platforms: dep.platforms }
          end
          result
        end
      end
    end

    private

    #
    # Given a bunch of locks (name -> { dependencies: [name,name] }) and a
    # dependency name, add its dependencies to the result transitively.
    #
    def transitive_dependencies(locks, name, dep_key, result = Set.new)
      locks[name][dep_key].each do |dep|
        # Only ever add a dep once, so we don't infinitely recurse
        if result.add?(dep)
          transitive_dependencies(locks, dep, dep_key, result)
        end
      end
      result
    end

    #
    # Get source and version metadata for the given Bundler spec (coming from a lockfile).
    #
    # @return Hash { version: <version>, git: <git>, path: <path>, source: <source>, ref: <ref> }
    #
    def lock_source_metadata(spec)
      # Copy source information from included Gemfile
      result = {}
      case spec.source
      when Bundler::Source::Rubygems
        result[:source] = spec.source.remotes.first.to_s
      when Bundler::Source::Git
        result[:git] = spec.source.uri.to_s
        result[:ref] = spec.source.revision
      when Bundler::Source::Path
        result[:path] = spec.source.path.to_s
      else
        raise "Unknown source #{spec.source} for gem #{spec.name}"
      end
      result
    end
  end
end
