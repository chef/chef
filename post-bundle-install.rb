#!/usr/bin/env ruby

require "fileutils"

gem_home = Gem.paths.home

puts "fixing bundle installed gems in #{gem_home}"

# Bundler can leave several revisions of a Git gem in GEM_HOME. Use the
# lockfile-selected checkout for the temporary chef-powershell build below.
active_chef_powershell_path = `bundle show chef-powershell`.strip
active_chef_powershell_root = File.expand_path(File.join(active_chef_powershell_path, "..")) unless active_chef_powershell_path.empty?

# BEGIN TEMPORARY chef-powershell pre-release testing
# Test Chef compatibility before chef-powershell is released as a gem or Habitat package.
# Remove this method and its call when Chef switches back to a released gem.
def prepare_chef_powershell(gempath, gemspec_path)
  return unless RUBY_PLATFORM =~ /mswin|mingw|windows/

  ENV["HAB_LICENSE"] = "accept-no-persist"

  unless system("hab", "--version", out: File::NULL, err: File::NULL)
    system("choco", "install", "habitat", "-y", "--no-progress", "--version=1.6.1245") or raise "Habitat installation failed"
  end

  system("hab", "--version") or raise "Habitat is unavailable after installation"

  # Habitat names its studio directory after the full source path. Bundler's
  # deeply nested git-checkout path pushes some Habitat-built file paths
  # (e.g. the VS Build Tools NuGet SDK resolver) past MAX_PATH, which the
  # classic .NET Framework assembly binder fails to load. Build from a
  # short, fixed path instead to avoid this entirely.
  short_build_root = "C:/hs/ps-build"

  FileUtils.rm_rf(short_build_root)
  FileUtils.mkdir_p(File.dirname(short_build_root))
  FileUtils.cp_r(gempath, short_build_root)

  Dir.chdir(short_build_root) do
    system("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", "$env:HAB_STUDIOS_HOME = 'C:\\hs'; hab pkg build Habitat") or raise "chef-powershell Habitat build failed"

    results_script = Dir["results/last_build.ps1"].first
    artifact = Dir["results/*.hart"].max_by { |path| File.mtime(path) }
    raise "chef-powershell Habitat build produced no artifact" unless results_script && artifact

    system("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", ". '#{results_script}'; hab pkg install '#{artifact}'") or raise "chef-powershell Habitat package install failed"
  end

  package_path = `hab pkg path chef/chef-powershell-shim`.strip
  raise "Unable to locate the chef-powershell Habitat package" if package_path.empty?

  destination = File.join(File.dirname(gemspec_path), "bin", "ruby_bin_folder", "AMD64")
  FileUtils.mkdir_p(destination)
  FileUtils.cp_r(Dir[File.join(package_path, "bin", "*")], destination)

  FileUtils.rm_rf(short_build_root)
end
# END TEMPORARY chef-powershell pre-release testing

# Install gems from git repos.  This makes the assumption that there is a <gem_name>.gemspec and
# you can simply gem build + gem install the resulting gem, so nothing fancy.  This does not use
# rake install since we need --conservative --minimal-deps in order to not install duplicate gems.
#
Dir["#{gem_home}/bundler/gems/*"].each do |gempath|
  matches = File.basename(gempath).match(/.*-[A-Fa-f0-9]{12}/)
  next unless matches

  gemspec_path = Dir["#{gempath}/*.gemspec", "#{gempath}/**/*.gemspec"].first
  next unless gemspec_path

  gem_name = File.basename(gemspec_path, ".gemspec")
  # FIXME: should strip any valid ruby platform off of the gem_name if it matches

  # FIXME: should omit the gem which is in the current directory and not hard code chef
  next if %w{chef chef-universal-mingw-ucrt proxifier}.include?(gem_name)

  if gem_name == "chef-powershell"
    next unless active_chef_powershell_root && File.expand_path(gempath) == active_chef_powershell_root
  end

  next if gem_name.match?(/ruby.shadow/) && (RUBY_PLATFORM.include?("aix") || RUBY_PLATFORM =~ /mswin|mingw|windows/)

  puts "re-installing #{gem_name}..."

  # BEGIN TEMPORARY chef-powershell pre-release testing
  prepare_chef_powershell(gempath, gemspec_path) if gem_name == "chef-powershell"
  # END TEMPORARY chef-powershell pre-release testing

  Dir.chdir(File.dirname(gemspec_path)) do
    system("gem build #{File.basename(gemspec_path)}") or raise "gem build failed"
    # On AIX (Ruby 3.0.3), git-sourced gems often declare required_ruby_version >= 3.1.0.
    # Without --ignore-dependencies, gem install falls back to rubygems.org and installs
    # the wrong gem version with different dependency constraints (e.g. rest-client on
    # rubygems.org requires http-accept >= 1.7.0, < 2.0 instead of ~> 2.1.0).
    # Use --ignore-dependencies on AIX since all deps are already installed by bundle install.
    install_flags = RUBY_PLATFORM.include?("aix") ? "--ignore-dependencies --no-document" : "--conservative --minimal-deps --no-document"
    system("gem install #{gem_name}*.gem #{install_flags}") or raise "gem install failed"
  end
end

def patch_ssl_env_hack(ssl_env_hack)
  # the constant SSL_ENV_CACERT_PATCH is a proxy for whether the SSL_CERT_FILE environment variable
  # will be set by the ssl_env_hack.rb file.  This is used to ensure that the CA bundle
  # is set correctly in omnibus installations of Chef Infra Client if the user is using certs/cacert.pem
  # instead of cert.pem. Because we're reinstalling openssl gem for 3.x versions, we need to ensure that
  # openssl.rb requires ssl_env_hack.rb, which will set the SSL_CERT_FILE environment variable
  ssl_env_hack_patch = <<-PATCH
  SSL_ENV_CACERT_PATCH=true unless defined?(SSL_ENV_CACERT_PATCH)
  PATCH

  File.open(ssl_env_hack, "r+") do |f|
    unpatched_ssl_env_hack_rb = f.read
    if unpatched_ssl_env_hack_rb =~ /SSL_ENV_CACERT_PATCH/
      puts "skipping #{ssl_env_hack} as it already has SSL_ENV_CACERT_PATCH"
      next
    end

    f.rewind
    f.write(ssl_env_hack_patch)
    f.write(unpatched_ssl_env_hack_rb)
  end
  puts "patched #{ssl_env_hack} to include SSL_ENV_CACERT_PATCH"
end

def patch_openssl(openssl)
  puts openssl
  File.open(openssl, "r+") do |f|
    unpatched_openssl_rb = f.read
    if unpatched_openssl_rb =~ /require\s+['"]ssl_env_hack['"]/
      puts "skipping #{openssl} as it already has ssl_env_hack"
      next
    end

    f.rewind
    # This is a workaround for the openssl gem not being able to find the CA bundle in omnibus installations
    # and not setting SSL_CERT_FILE if it's not already set.
    f.write("\nrequire 'ssl_env_hack'\n")
    f.write(unpatched_openssl_rb)
  end
  puts "patched #{openssl} to include ssl_env_hack"
end

if RUBY_PLATFORM =~ /mswin|mingw|windows/
  puts "Patching ssl_env_hack.rb to include SSL_ENV_CACERT_PATCH"

  # ssl_env_hack.rb in chef is superseded by foundation copy in omnibus,
  # but patch it if it doesn't have SSL_ENV_CACERT_PATCH defined.
  $:.each do |lib|
    puts "checking for ssl_env_hack in #{lib}"
    Dir["#{lib}/**/ssl_env_hack.rb"].each do |ssl_env_hack|
      puts "found #{ssl_env_hack}"
      patch_ssl_env_hack(ssl_env_hack)
      File.readlines(ssl_env_hack).each do |line|
        puts line
      end
    end
  end

  puts "Found openssl.rb files in the following gem paths:"
  Dir["#{gem_home}/**/openssl-*/lib/openssl.rb"].each do |openssl|
    patch_openssl(openssl)
  end

  puts "Patch openssl.rb in the load path as well"
  $:.each do |lib|
    openssl_rb = File.join(lib, "openssl.rb")
    patch_openssl(openssl_rb) if File.exist?(openssl_rb)
  end

  puts "Including openssl"
  require "openssl"
  puts "::SSL_ENV_CACERT_PATCH is #{defined?(::SSL_ENV_CACERT_PATCH) ? "defined" : "not defined"}"
end

default_gem_list = {
  resolv: "0.2.1",
  uri: "0.12.4",
  zlib: "2.1.1",
  erb: "2.2.3",
}

# On AIX, the omnibus toolchain/foundation ships Ruby 3.0.3.  Replacing the
# default resolv gem with a newer version (0.7.x) causes
# "undefined method 'request' for nil:NilClass" in RubyGems' HTTP client
# because the newer resolv changes internal APIs that RubyGems 3.0 expects.
# Skip the default-gem replacement on AIX to keep the default gems intact.
unless RUBY_PLATFORM.include?("aix")
  default_gem_list.each do |gem_name, version|
    # Handle resolv gem conflict with default gem
    puts "Checking #{gem_name} gem installation..."
    gem_info = `gem info #{gem_name}`

    if gem_info.include?("default):") && gem_info.match?(/#{gem_name} \([0-9., ]*#{version}[0-9., ]*\)/)
      # Extract the default gem path
      default_path = gem_info.match(/default\): (.+)$/)[1]

      if default_path
        gemspec_path = File.join(default_path.strip, "specifications", "default", "#{gem_name}-#{version}.gemspec")

        if File.exist?(gemspec_path)
          puts "Removing default #{gem_name} gemspec: #{gemspec_path}"
          File.delete(gemspec_path)
        end
      end

      puts "Installing #{gem_name} gem..."
      system("gem install #{gem_name}") or raise "gem install #{gem_name} failed" # NOSONAR
      puts "#{gem_name} gem installed successfully"
    end
  end
end
