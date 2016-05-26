require "bundler"
require "shellwords"

module BundleUtil
  PLATFORMS = { "windows" => %w{ruby x86-mingw32} }

  def project_root
    File.expand_path("../..", __FILE__)
  end

  def bundle_platform
    File.join(project_root, "tasks", "bin", "bundle-platform")
  end

  # Parse the output of "bundle outdated" and get the list of gems that
  # were outdated
  def parse_bundle_outdated(bundle_outdated_output)
    result = []
    bundle_outdated_output.each_line do |line|
      if line =~ /^\s*\* (.+) \(newest ([^,]+), installed ([^,)])*/
        gem_name, newest_version, installed_version = $1, $2, $3
        result << [ line, gem_name ]
      end
    end
    result
  end

  def with_bundle_unfrozen(cwd: nil, leave_frozen: false)
    bundle "config --delete frozen", cwd: cwd
    begin
      yield
    ensure
      bundle "config --local frozen 1", cwd: cwd unless leave_frozen
    end
  end

  # Run bundle-platform with the given ruby platform(s)
  def bundle(args, gemfile: nil, platform: nil, cwd: nil, extract_output: false, delete_gemfile_lock: false)
    args = args.split(/\s+/)
    if cwd
      prefix = "[#{cwd}] "
    end
    cwd = File.expand_path(cwd || ".", project_root)
    Bundler.with_clean_env do
      Dir.chdir(cwd) do
        gemfile ||= "Gemfile"
        gemfile = File.expand_path(gemfile, cwd)
        raise "No platform #{platform} (supported: #{PLATFORMS.keys.join(", ")})" if platform && !PLATFORMS[platform]

        # First delete the gemfile.lock
        if delete_gemfile_lock
          if File.exist?("#{gemfile}.lock")
            puts "Deleting #{gemfile}.lock ..."
            File.delete("#{gemfile}.lock")
          end
        end

        # Run the bundle command
        ruby_platforms = platform ? PLATFORMS[platform].join(" ") : "ruby"
        cmd = Shellwords.join([
          Gem.ruby,
          "-S",
          bundle_platform,
          ruby_platforms,
          "_#{desired_bundler_version}_",
          *args,
        ])
        puts "#{prefix}#{Shellwords.join(["bundle", *args])}#{platform ? " for #{platform} platform" : ""}:"
        with_gemfile(gemfile) do
          puts "#{prefix}BUNDLE_GEMFILE=#{gemfile}"
          puts "#{prefix}> #{cmd}"
          if extract_output
            `#{cmd}`
          else
            unless system(bundle_platform, ruby_platforms, "_#{desired_bundler_version}_", *args)
              raise "#{bundle_platform} failed: exit code #{$?}"
            end
          end
        end
      end
    end
  end

  def with_gemfile(gemfile)
    old_gemfile = ENV["BUNDLE_GEMFILE"]
    ENV["BUNDLE_GEMFILE"] = gemfile
    begin
      yield
    ensure
      if old_gemfile
        ENV["BUNDLE_GEMFILE"] = old_gemfile
      else
        ENV.delete("BUNDLE_GEMFILE")
      end
    end
  end

  def platforms
    PLATFORMS.keys
  end

  def desired_bundler_version
    @desired_bundler_version ||= begin
      omnibus_overrides = File.join(project_root, "omnibus_overrides.rb")
      File.readlines(omnibus_overrides).each do |line|
        return $1 if line =~ /^override :bundler, version: "(.+)"$/
      end
    end
  end
end
