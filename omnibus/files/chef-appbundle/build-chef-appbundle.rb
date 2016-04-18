require_relative "../chef-gem/build-chef-gem"

module BuildChefAppbundle
  include BuildChefGem

  def lockdown_gem(gem_name)
    shared_gemfile = self.shared_gemfile

    # Update the Gemfile to restrict to built versions so that bundle installs
    # will do the right thing
    block "Lock down the #{gem_name} gem" do
      installed_path = shellout!("#{bundle_bin} show #{gem_name}", env: env, cwd: install_dir).stdout.chomp
      installed_gemfile = File.join(installed_path, "Gemfile")

      #
      # Include the main distribution Gemfile in the gem's Gemfile
      #
      # NOTE: if this fails and the build retries, you will see this multiple
      # times in the file.
      #
      distribution_gemfile = Pathname(shared_gemfile).relative_path_from(Pathname(installed_gemfile)).to_s
      gemfile_text = <<-EOM.gsub(/^\s+/, "")
        # Lock gems that are part of the distribution
        distribution_gemfile = File.expand_path(#{distribution_gemfile.inspect}, __FILE__)
        instance_eval(IO.read(distribution_gemfile), distribution_gemfile)
      EOM
      gemfile_text << IO.read(installed_gemfile)
      create_file(installed_gemfile) { gemfile_text }

      # Remove the gemfile.lock
      remove_file("#{installed_gemfile}.lock") if File.exist?("#{installed_gemfile}.lock")

      # If it's frozen, make it not be.
      shellout!("#{bundle_bin} config --delete frozen")

      # This could be changed to `bundle install` if we wanted to actually
      # install extra deps out of their gemfile ...
      shellout!("#{bundle_bin} lock", env: env, cwd: installed_path)
      # bundle lock doesn't always tell us when it fails, so we have to check :/
      unless File.exist?("#{installed_gemfile}.lock")
        raise "bundle lock failed: no #{installed_gemfile}.lock created!"
      end

      # Ensure all the gems we need are actually installed (if the bundle adds
      # something, we need to know about it so we can include it in the main
      # solve).
      # Save bundle config and modify to use --without development before checking
      bundle_config = File.expand_path("../.bundle/config", installed_gemfile)
      orig_config = IO.read(bundle_config) if File.exist?(bundle_config)
      # "test", "changelog" and "guard" come from berkshelf, "maintenance" comes from chef
      # "tools" and "integration" come from inspec
      shellout!("#{bundle_bin} config --local without #{without_groups.join(":")}", env: env, cwd: installed_path)
      shellout!("#{bundle_bin} config --local frozen 1")

      shellout!("#{bundle_bin} check", env: env, cwd: installed_path)

      # Restore bundle config
      if orig_config
        create_file(bundle_config) { orig_config }
      else
        remove_file bundle_config
      end
    end
  end

  # appbundle the gem, making /opt/chef/bin/<binary> do the superfast pinning
  # thing.
  #
  # To protect the app from loading the wrong versions of things, it uses
  # appbundler against the resulting file.
  #
  # Relocks the Gemfiles inside the specified gems (e.g. berkshelf, test-kitchen,
  # chef) to use the distribution's chosen gems.
  def appbundle_gem(gem_name)
    # First lock the gemfile down.
    lockdown_gem(gem_name)

    shared_gemfile = self.shared_gemfile

    # Ensure the main bin dir exists
    bin_dir = File.join(install_dir, "bin")
    mkdir(bin_dir)

    block "Lock down the #{gem_name} gem" do
      installed_path = shellout!("#{bundle_bin} show #{gem_name}", env: env, cwd: install_dir).stdout.chomp

      # appbundle the gem
      appbundler_args = [ installed_path, bin_dir, gem_name ]
      appbundler_args = appbundler_args.map { |a| ::Shellwords.escape(a) }
      shellout!("#{appbundler_bin} #{appbundler_args.join(" ")}", env: env, cwd: installed_path)
    end
  end
end
