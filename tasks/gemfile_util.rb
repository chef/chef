require "bundler"

module GemfileUtil
  #
  # Given a set of dependencies with groups in them, and a resolved set of
  # gemspecs (with dependency info in them), creates a full set of specs
  # with group information on it. If A is in groups x and y, and A depends on
  # B and C, then B and C are also in groups x and y.
  #
  class GemGroups < Hash
    def initialize(resolved)
      @resolved = resolved
    end
    attr_reader :resolved

    def add_dependency(dep)
      add_gem_groups(dep.name, dep.groups)
    end

    private

    def add_gem_groups(name, groups)
      self[name] ||= []
      difference = groups - self[name]
      unless difference.empty?
        self[name] += difference
        spec = resolved.find { |spec| spec.name == name }
        if spec
          spec.dependencies.each do |spec|
            add_gem_groups(spec.name, difference)
          end
        end
      end
    end
  end

  def calculate_dependents(spec_set)
    dependents = {}
    spec_set.each do |spec|
      dependents[spec] ||= []
    end
    spec_set.each do |spec|
      spec.dependencies.each do |dep|
        puts "#{dep.class} -> #{spec.class}"
        dependents[dep] << spec
      end
    end
    dependents
  end

  def include_locked_gemfile(gemfile)
    #
    # Read the gemfile and inject its locks as first-class dependencies
    #
    current_source = nil
    bundle = Bundler::Definition.build(gemfile, "#{gemfile}.lock", nil)

    # Go through and create the actual gemfile from the given locks and
    # groups.
    bundle.resolve.sort_by { |spec| spec.name }.each do |spec|
      # bundler can't be installed by bundler so don't pin it.
      next if spec.name == "bundler"
      dep = bundle.dependencies.find { |d| d.name == spec.name }
      gem_metadata = ""
      if dep
        gem_metadata << ", groups: #{dep.groups.inspect}" if dep.groups != [:default]
        gem_metadata << ", platforms: #{dep.platforms.inspect}" if dep.platforms && !dep.platforms.empty?
      end
      case spec.source
      when Bundler::Source::Rubygems
        if current_source
          if current_source != spec.source
            raise "Gem #{spec.name} has source #{spec.source}, but other gems have #{current_source}. Multiple rubygems sources are not supported."
          end
        else
          current_source = spec.source
          add_gemfile_line("source #{spec.source.remotes.first.to_s.inspect}", __LINE__)
        end
        add_gemfile_line("gem #{spec.name.inspect}, #{spec.version.to_s.inspect}#{gem_metadata}", __LINE__)
      when Bundler::Source::Git
        add_gemfile_line("gem #{spec.name.inspect}, git: #{spec.source.uri.to_s.inspect}, ref: #{spec.source.revision.inspect}#{gem_metadata}", __LINE__)
      when Bundler::Source::Path
        add_gemfile_line("gem #{spec.name.inspect}, path: #{spec.source.path.to_s.inspect}#{gem_metadata}", __LINE__)
      else
        raise "Unknown source #{spec.source} for gem #{spec.name}"
      end
    end
  rescue
    puts $!
    puts $!.backtrace
    raise
  end

  private

  def add_gemfile_line(line, lineno)
    instance_eval(line, __FILE__, lineno)
  end
end
