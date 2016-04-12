require "bundler"
require "set"

module GemfileUtil
  #
  # Adds `override: true`, which allows your statement to override any other
  # gem statement about the same gem in the Gemfile.
  #
  def gem(name, *args)
    Bundler.ui.debug "gem #{name}, #{args.join(", ")}"
    current_dep = dependencies.find { |dep| dep.name == name }

    # Set path to absolute in case this is an included Gemfile in bundler 1.11.2 and below
    options = args[-1].is_a?(Hash) ? args[-1] : {}
    if options[:path]
      # path sourced gems are assumed to be overrides.
      options[:override] = true
      # options[:path] = File.expand_path(options[:path], Bundler.default_gemfile.dirname)
    end
    # Handle override
    if options[:override]
      override = true
      options.delete(:override)
      if current_dep
        dependencies.delete(current_dep)
      end
    else
      # If an override gem already exists, and we're not an override gem,
      # ignore this gem in favor of the override (but warn if they don't match)
      if overridden_gems.include?(name)
        args.pop if args[-1].is_a?(Hash)
        version = args || [">=0"]
        desired_dep = Bundler::Dependency.new(name, version, options.dup)
        if desired_dep =~ current_dep
          Bundler.ui.debug "Replaced Gemfile dependency #{desired_dep} (#{desired_dep.source}) with override gem #{current_dep} (#{current_dep.source})"
        else
          Bundler.ui.warn "Replaced Gemfile dependency #{desired_dep} (#{desired_dep.source}) with incompatible override gem #{current_dep} (#{current_dep.source})"
        end
        return
      end
    end

    # Add the gem normally
    super

    overridden_gems << name if override

    # Emit a warning if we're replacing a dep that doesn't match
    if current_dep && override
      added_dep = dependencies.find { |dep| dep.name == name }
      if added_dep =~ current_dep
        Bundler.ui.debug "Replaced Gemfile dependency #{current_dep} (#{current_dep.source}) with override gem #{added_dep} (#{added_dep.source})"
      else
        Bundler.ui.warn "Replaced Gemfile dependency #{current_dep} (#{current_dep.source}) with incompatible override gem #{added_dep} (#{added_dep.source})"
      end
    end
  end

  def overridden_gems
    @overridden_gems ||= Set.new
  end

  #
  # Include all gems in the locked gemfile.
  #
  # @param gemfile Path to the Gemfile to load (relative to your Gemfile)
  # @param groups A list of groups to include (whitelist). If not passed (or set
  #               to nil), all gems will be selected.
  # @param without_groups A list of groups to ignore. Gems will be excluded from
  #                       the results if all groups they belong to are ignored.
  #                       This matches bundler's `without` behavior.
  # @param gems A list of gems to include above and beyond the given groups.
  #             Gems in this list must be explicitly included in the Gemfile
  #             with a `gem "gem_name", ...` line or they will be silently
  #             ignored.
  #
  def include_locked_gemfile(gemfile, groups: nil, without_groups: nil, gems: [])
    gemfile = File.expand_path(gemfile, Bundler.default_gemfile.dirname)
    gems = Set.new(gems) + GemfileUtil.select_gems(gemfile, groups: nil, without_groups: nil)
    specs = GemfileUtil.locked_gems("#{gemfile}.lock", gems)
    specs.each do |name, version: nil, **options|
      options = options.merge(override: true)
      Bundler.ui.debug("Adding gem #{name}, #{version}, #{options} from #{gemfile}")
      gem name, version, options
    end
  rescue
    puts "ERROR: #{$!}"
    puts $!.backtrace
    raise
  end

  #
  # Include all gems in the locked gemfile.
  #
  # @param current_gemfile The Gemfile you are currently loading (`self`).
  # @param gemfile Path to the Gemfile to load (relative to your Gemfile)
  # @param groups A list of groups to include (whitelist). If not passed (or set
  #               to nil), all gems will be selected.
  # @param without_groups A list of groups to ignore. Gems will be excluded from
  #                       the results if all groups they belong to are ignored.
  #                       This matches bundler's `without` behavior.
  # @param gems A list of gems to include above and beyond the given groups.
  #             Gems in this list must be explicitly included in the Gemfile
  #             with a `gem "gem_name", ...` line or they will be silently
  #             ignored.
  #
  def self.include_locked_gemfile(current_gemfile, gemfile, groups: nil, without_groups: nil, gems: [])
    current_gemfile.instance_eval do
      extend GemfileUtil
      include_locked_gemfile(gemfile, groups: groups, without_groups: without_groups, gems: [])
    end
  end

  #
  # Select the desired gems, sans dependencies, from the gemfile.
  #
  # @param gemfile Path to the Gemfile to load
  # @param groups A list of groups to include (whitelist). If not passed (or set
  #               to nil), all gems will be selected.
  # @param without_groups A list of groups to ignore. Gems will be excluded from
  #                       the results if all groups they belong to are ignored.
  #                       This matches bundler's `without` behavior.
  #
  # @return An array of strings with the names of the given gems.
  #
  def self.select_gems(gemfile, groups: nil, without_groups: nil)
    Bundler.with_clean_env do
      # Set BUNDLE_GEMFILE to the new gemfile temporarily so all bundler's things work
      # This works around some issues in bundler 1.11.2.
      ENV["BUNDLE_GEMFILE"] = gemfile

      parsed_gemfile = Bundler::Dsl.new
      parsed_gemfile.eval_gemfile(gemfile)
      deps = parsed_gemfile.dependencies.select do |dep|
        dep_groups = dep.groups
        dep_groups = dep_groups & groups if groups
        dep_groups = dep_groups - without_groups if without_groups
        dep_groups.any?
      end
      deps.map { |dep| dep.name }
    end
  end

  #
  # Get all gems in the locked gemfile that start from the given gem set.
  #
  # @param lockfile Path to the Gemfile to load
  # @param groups A list of groups to include (whitelist). If not passed (or set
  #               to nil), all gems will be selected.
  # @param without_groups A list of groups to ignore. Gems will be excluded from
  #                       the results if all groups they belong to are ignored.
  #                       This matches bundler's `without` behavior.
  # @param gems A list of gems to include above and beyond the given groups.
  #             Gems in this list must be explicitly included in the Gemfile
  #             with a `gem "gem_name", ...` line or they will be silently
  #             ignored.
  # @param include_development_deps Whether to include development dependencies
  #                                 or runtime only.
  #
  # @return Hash[String, Hash] A hash from gem_name ->  { version: <version>, source: <source>, git: <git>, path: <path>, ref: <ref> }
  #
  def self.locked_gems(lockfile, gems, include_development_deps: false)
    # Grab all the specs from the lockfile
    parsed_lockfile = Bundler::LockfileParser.new(IO.read(lockfile))
    specs = {}
    parsed_lockfile.specs.each { |s| specs[s.name] = s }

    # Select the desired gems, as well as their dependencies
    to_process = Array(gems)
    results = {}
    while to_process.any?
      gem_name = to_process.pop
      next if gem_name == "bundler" # can't be bundled. Messes things up. Stop it.
      # Only process each gem once
      unless results.has_key?(gem_name)
        spec = specs[gem_name]
        unless spec
          raise "Gem #{gem_name.inspect} was requested but was not in #{lockfile}! Gems in lockfile: #{specs.keys}"
        end
        results[gem_name] = gem_metadata(spec, lockfile)
        spec.dependencies.each do |dep|
          if dep.type == :runtime || include_development_deps
            to_process << dep.name
          end
        end
      end
    end

    results
  end

  private

  #
  # Get metadata for the given Bundler spec (coming from a lockfile).
  #
  # @return Hash { version: <version>, git: <git>, path: <path>, source: <source>, ref: <ref> }
  #
  def self.gem_metadata(spec, lockfile)
    # Copy source information from included Gemfile
    result = {}
    case spec.source
    when Bundler::Source::Rubygems
      result[:source] = spec.source.remotes.first.to_s
      result[:version] = spec.version.to_s
    when Bundler::Source::Git
      result[:git] = spec.source.uri.to_s
      result[:ref] = spec.source.revision
    when Bundler::Source::Path
      # Path is relative to the lockfile (if it's relative at all)
      result[:path] = File.expand_path(spec.source.path.to_s, File.dirname(lockfile))
    else
      raise "Unknown source #{spec.source} for gem #{spec.name}"
    end
    result
  end

end
