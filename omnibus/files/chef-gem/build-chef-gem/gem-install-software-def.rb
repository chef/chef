require "bundler"
require "omnibus"
require_relative "../build-chef-gem"

module BuildChefGem
  class GemInstallSoftwareDef
    def self.define(software, software_filename)
      new(software, software_filename).send(:define)
    end

    include BuildChefGem
    include Omnibus::Logging

    protected

    def initialize(software, software_filename)
      @software = software
      @software_filename = software_filename
    end

    attr_reader :software, :software_filename

    def define
      software.name "#{File.basename(software_filename)[0..-4]}"
      software.default_version gem_version

      # If the source directory for building stuff changes, tell omnibus to
      # de-cache us
      software.source path: File.expand_path("../..", __FILE__)

      # ruby and bundler and friends
      software.dependency "ruby"
      software.dependency "rubygems"

      gem_name = self.gem_name
      gem_version = self.gem_version
      gemspec = self.gemspec
      lockfile_path = self.lockfile_path

      software.build do
        extend BuildChefGem

        if gem_version == "<skip>"
          if gemspec
            block do
              log.info(log_key) { "#{gem_name} has source #{gemspec.source.name} in #{lockfile_path}. We only cache rubygems.org installs in omnibus to keep things simple. The chef step will build #{gem_name} ..." }
            end
          else
            block do
              log.info(log_key) { "#{gem_name} is not in the #{lockfile_path}. This can happen if your OS doesn't build it, or if chef no longer depends on it. Skipping ..." }
            end
          end
        else
          block do
            log.info(log_key) { "Found version #{gem_version} of #{gem_name} in #{lockfile_path}. Building early to take advantage of omnibus caching ..." }
          end
          gem "install #{gem_name} -v #{gem_version} --no-doc --no-ri --ignore-dependencies --verbose -- #{install_args_for(gem_name)}", env: env
        end
      end
    end

    # Path above omnibus (where Gemfile is)
    def root_path
      File.expand_path("../../../../..", __FILE__)
    end

    def gemfile_path
      # gemfile path could be relative to software filename (and often is)
      @gemfile_path ||= begin
        # Grab the version (and maybe source) from the lockfile so omnibus knows whether
        # to toss the cache or not
        gemfile_path = File.join(root_path, "Gemfile")
        platform_gemfile_path = "#{gemfile_path}.#{Omnibus::Ohai["platform"]}"
        if File.exist?(platform_gemfile_path)
          gemfile_path = platform_gemfile_path
        end
        gemfile_path
      end
    end

    def lockfile_path
      @lockfile_path ||= "#{gemfile_path}.lock"
    end

    def gem_name
      @gem_name ||= begin
        # File must be named chef-<gemname>.rb
        # Will look at chef/Gemfile.lock and install that version of the gem using "gem install"
        # (and only that version)
        if File.basename(software_filename) =~ /^chef-gem-(.+)\.rb$/
          $1
        else
          raise "#{software_filename} must be named chef-<gemname>.rb to build a gem automatically"
        end
      end
    end

    def gemspec
      @gemspec ||= begin
        old_frozen = Bundler.settings[:frozen]
        Bundler.settings[:frozen] = true
        begin
          bundle = Bundler::Definition.build(gemfile_path, lockfile_path, nil)
          dependencies = bundle.dependencies.select { |d| (d.groups - without_groups).any? }
          # This is sacrilege: figure out a way we can grab the list of dependencies *without*
          # requiring everything to be installed or calling private methods ...
          gemspec = bundle.resolve.for(bundle.send(:expand_dependencies, dependencies)).find { |s| s.name == gem_name }
          if gemspec
            log.info(software.name) { "Using #{gem_name} version #{gemspec.version} from #{gemfile_path}" }
          elsif bundle.resolve.find { |s| s.name == gem_name }
            log.info(software.name) { "#{gem_name} not loaded from #{gemfile_path}, skipping" }
          else
            raise "#{gem_name} not found in #{gemfile_path} or #{lockfile_path}"
          end
          gemspec
        ensure
          Bundler.settings[:frozen] = old_frozen
        end
      end
    end

    def gem_version
      @gem_version ||= begin
        if gemspec && gemspec.source.name == "rubygems repository https://rubygems.org/"
          gemspec.version.to_s
        else
          "<skip>"
        end
      end
    end
  end
end
