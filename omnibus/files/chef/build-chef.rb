require "shellwords"
require "pathname"
require "bundler"
require_relative "../chef-gem/build-chef-gem"
require_relative "../../../version_policy"

# We use this to break up the `build` method into readable parts
module BuildChef
  include BuildChefGem

  def create_bundle_config(gemfile, without: without_groups, retries: nil, jobs: nil, frozen: nil)
    bundle_config = File.expand_path("../.bundle/config", gemfile)

    block "Put build config into #{bundle_config}: #{{ without: without, retries: retries, jobs: jobs, frozen: frozen }}" do
      # bundle config build.nokogiri #{nokogiri_build_config} messes up the line,
      # so we write it directly ourselves.
      new_bundle_config = "---\n"
      new_bundle_config << "BUNDLE_WITHOUT: #{Array(without).join(":")}\n" if without
      new_bundle_config << "BUNDLE_RETRY: #{retries}\n" if retries
      new_bundle_config << "BUNDLE_JOBS: #{jobs}\n" if jobs
      new_bundle_config << "BUNDLE_FROZEN: '1'\n" if frozen
      all_install_args.each do |gem_name, install_args|
        new_bundle_config << "BUNDLE_BUILD__#{gem_name.upcase}: #{install_args}\n"
      end
      create_file(bundle_config) { new_bundle_config }
    end
  end

  #
  # Get the (possibly platform-specific) path to the Gemfile.
  #
  def project_gemfile
    File.join(project_dir, "Gemfile")
  end

  #
  # Some gems we installed don't end up in the `gem list` due to the fact that
  # they have git sources (`gem 'chef', github: 'chef/chef'`) or paths (`gemspec`
  # or `gem 'chef-config', path: 'chef-config'`). To get them in there, we need
  # to go through these gems, run `rake install` from their top level, and
  # then delete the git cached versions.
  #
  # Once we finish with all this, we update the Gemfile that will end up in the
  # top-level install so that it doesn't have git or path references anymore.
  #
  def properly_reinstall_git_and_path_sourced_gems
    # Emit blank line to separate different tasks
    block { log.info(log_key) { "" } }
    project_env = env.dup.merge("BUNDLE_GEMFILE" => project_gemfile)

    # Reinstall git-sourced or path-sourced gems, and delete the originals
    block "Reinstall git-sourced gems properly" do
      # Grab info about the gem environment so we can make decisions
      gemdir = shellout!("#{gem_bin} environment gemdir", env: env).stdout.chomp
      gem_install_dir = File.join(gemdir, "gems")

      # bundle list --paths gets us the list of gem install paths. Get the ones
      # that are installed local (git and path sources like `gem :x, github: 'chef/x'`
      # or `gem :x, path: '.'` or `gemspec`). To do this, we just detect which ones
      # have properly-installed paths (in the `gems` directory that shows up when
      # you run `gem list`).
      locally_installed_gems = shellout!("#{bundle_bin} list --paths", env: project_env, cwd: project_dir).
        stdout.lines.select { |gem_path| !gem_path.start_with?(gem_install_dir) }

      # Install the gems for real using `rake install` in their directories
      locally_installed_gems.each do |gem_path|
        gem_path = gem_path.chomp
        # We use the already-installed bundle to rake install, because (hopefully)
        # just rake installing doesn't require anything special.
        # Emit blank line to separate different tasks
        log.info(log_key) { "" }
        log.info(log_key) { "Properly installing git or path sourced gem #{gem_path} using rake install" }
        shellout!("#{bundle_bin} exec #{rake_bin} install", env: project_env, cwd: gem_path)
      end
    end
  end

  def install_shared_gemfile
    # Emit blank line to separate different tasks
    block { log.info(log_key) { "" } }

    shared_gemfile = self.shared_gemfile
    project_env = env.dup.merge("BUNDLE_GEMFILE" => project_gemfile)

    # Show the config for good measure
    bundle "config", env: project_env

    # Make `Gemfile` point to these by removing path and git sources and pinning versions.
    block "Rewrite Gemfile using all properly-installed gems" do
      gem_pins = ""
      result = []
      shellout!("#{bundle_bin} list", env: project_env).stdout.lines.map do |line|
        if line =~ /^\s*\*\s*(\S+)\s+\((\S+).*\)\s*$/
          name, version = $1, $2
          # rubocop is an exception, since different projects disagree
          next if GEMS_ALLOWED_TO_FLOAT.include?(name)
          gem_pins << "gem #{name.inspect}, #{version.inspect}, override: true\n"
        end
      end

      # Find the installed chef gem by looking for lib/chef.rb
      chef_gem = File.expand_path("../..", shellout!("#{gem_bin} which chef", env: project_env).stdout.chomp)
      # Figure out the path to gemfile_util from there
      gemfile_util = Pathname.new(File.join(chef_gem, "tasks", "gemfile_util"))
      gemfile_util = gemfile_util.relative_path_from(Pathname.new(shared_gemfile).dirname)

      create_file(shared_gemfile) { <<-EOM }
        # Meant to be included in component Gemfiles at the beginning with:
        #
        #     instance_eval(IO.read("#{install_dir}/Gemfile"), "#{install_dir}/Gemfile")
        #
        # Override any existing gems with our own.
        require_relative "#{gemfile_util}"
        extend GemfileUtil
        #{gem_pins}
      EOM
    end

    shared_gemfile_env = env.dup.merge("BUNDLE_GEMFILE" => shared_gemfile)

    # Create a `Gemfile.lock` at the final location
    bundle "lock", env: shared_gemfile_env

    # Freeze the location's Gemfile.lock.
    create_bundle_config(shared_gemfile, frozen: true)
  end
end
