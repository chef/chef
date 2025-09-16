#!/usr/bin/env ruby
require 'fileutils'

gem_home = Gem.paths.home

puts "fixing bundle installed gems in #{gem_home}"

# Helper method to install gems with platform-specific handling
def install_platform_specific_gem(gempath, gem_name)
  puts "Found #{gem_name} at: #{gempath}"
  Dir.chdir(gempath) do
    if RUBY_PLATFORM.include?("mingw")
      # On Windows, we need the universal-mingw-ucrt version
      puts "re-installing #{gem_name} for Windows platform..."
      begin
        system("gem build #{gem_name}.gemspec --platform=universal-mingw-ucrt") or raise "gem build failed"
        system("gem install #{gem_name}-*-universal-mingw-ucrt.gem --conservative --minimal-deps --no-document") or raise "gem install failed"
        puts "Successfully installed #{gem_name} for Windows"
      rescue => e
        puts "Error installing Windows version: #{e.message}. Trying default build..."
        system("gem build #{gem_name}.gemspec") or puts "Default gem build failed too"
        system("gem install #{gem_name}-*.gem --conservative --minimal-deps --no-document") or puts "Default gem install failed too"
      end
    else
      # On Unix/Linux, use the standard version with ruby platform
      puts "re-installing #{gem_name} for Unix/Linux platform..."
      begin
        # For Linux, explicitly set the platform to ruby and ensure we're creating a vendored gem
        system("gem build #{gem_name}.gemspec") or raise "gem build failed"
        # Add --force to ensure it installs correctly
        system("gem install #{gem_name}-*.gem --conservative --minimal-deps --no-document --platform=ruby --force") or raise "gem install failed"
        puts "Successfully installed #{gem_name} for Unix/Linux"
        
        # Ensure the gem is properly linked in the vendor directory
        installed_gem_path = `gem which #{gem_name} 2>/dev/null`.strip.split('/lib/')[0]
        if installed_gem_path && !installed_gem_path.empty?
          puts "Installed gem found at: #{installed_gem_path}"
        else
          puts "Warning: Could not locate installed #{gem_name} gem path"
        end
      rescue => e
        puts "Error installing Unix/Linux version: #{e.message}"
        # Try one more time with default options
        puts "Attempting fallback installation for #{gem_name}..."
        system("gem install #{gem_name} --conservative --minimal-deps --no-document") or puts "Fallback gem install failed too"
      end
    end
  end
end

# Install gems from git repos.  This makes the assumption that there is a <gem_name>.gemspec and
# you can simply gem build + gem install the resulting gem, so nothing fancy.  This does not use
# rake install since we need --conservative --minimal-deps in order to not install duplicate gems.
#
Dir["#{gem_home}/bundler/gems/*"].each do |gempath|
  matches = File.basename(gempath).match(/.*-[A-Fa-f0-9]{12}/)
  next unless matches

  gem_name = File.basename(Dir["#{gempath}/*.gemspec"].first, ".gemspec")
  # FIXME: should strip any valid ruby platform off of the gem_name if it matches

  next unless gem_name

  # FIXME: should omit the gem which is in the current directory and not hard code chef
  # Also exclude gems that will be handled separately with platform-specific installation
  next if %w{chef chef-universal-mingw-ucrt proxifier ffi-libarchive-universal-mingw-ucrt rest-client rest-client-universal-mingw-ucrt}.include?(gem_name)

  puts "re-installing #{gem_name}..."

  Dir.chdir(gempath) do
    system("gem build #{gem_name}.gemspec") or raise "gem build failed"
    system("gem install #{gem_name}*.gem --conservative --minimal-deps --no-document") or raise "gem install failed"
  end

  # Starting in ffi 1.17, FFI ships native extensions. However, we don't
  # want that as we need them to be compiled in our omnibus environment so
  # they will hae the correct run path in the environment so they can find
  # their libraries.
  #
  # We've updated the gemspec file to force compilation (`force_ruby_platform`),
  # however, appbundler will end up re-running `gem install` on the gems
  # installed from git, which, for reasons that aren't entirely clear will
  # pull in the pre-packaged native extensions instead of the ones that were
  # already in our bundle.
  #
  # This will leave us with _two_ versions installed at the same version,
  # for example:
  #   ffi (1.17.1 ruby x86_64-linux-gnu, 1.16.0)
  #
  # This output shows 1.17.1 has both the one we compiled ('ruby') and the
  # pre-compiled ones (x86_64-linux-gnu). So, we walk everything that is
  # installed and for all versions 1.17 and higher, we remove the version
  # with native extensions.
  #
  # For more information, see:
  #   https://github.com/ffi/ffi/issues/1139

  puts "Cleaning up broken versions of ffi..."
  # Get a list of ffi versions, for anything 1.17 and newer, remove any
  # pre-compiled gems, only use the ones we installed compiled right now
  # which will have the right LD run path.
  r, w = IO.pipe
  spawn("gem list --exact ffi", out: w)
  w.close
  out = r.read
  r.close
  m = out.match(/ffi \((.*)\)/)
  versions = m[1].split(", ")
  versions.each do |ver|
    # split "1.17.1 ruby x86_64-linux-gnu" by spaces
    version_info = ver.split
    # first word is version
    version = version_info[0]
    # all the others are platforms
    platforms = version_info[1..]

    # split "1.17.1" by dots
    v = version.split(".")
    # we only care about 1.17 and higher
    next unless v[0].to_i > 1 || v[1].to_i >= 17

    # iterate through platforms
    platforms.each do |platform|
      next if platform == "ruby" || platform.include?("mingw") || platform.include?("darwin")

      # sometimes its reported with -gnu, sometimes not, but you need
      # -gnu here.
      platform << "-gnu" if platform.end_with?("linux")
      c = "gem uninstall ffi --platform #{platform} --version #{version} --all --force"
      puts c
      system(c)
    end
  end

  puts "Leftover ffi dependency tree..."
  system("gem dependency ffi")
end

# Handle platform-specific gems separately
# List of gems that need platform-specific handling
platform_specific_gems = ["ffi-libarchive", "rest-client"]

platform_specific_gems.each do |gem_base_name|
  puts "Processing platform-specific gem: #{gem_base_name}"
  gem_found = false
  
  # Special handling for ffi-libarchive due to consistent issues
  if gem_base_name == "ffi-libarchive" && !RUBY_PLATFORM.include?("mingw")
    puts "Special handling for ffi-libarchive on Linux platform"
    
    # First try direct installation with specific version
    if system("gem install ffi-libarchive -v 1.2.0 --conservative --minimal-deps --no-document --force")
      puts "Successfully installed ffi-libarchive via direct installation"
      gem_found = true
    else
      puts "Direct installation failed, trying from source..."
      # Try cloning and building from source
      system("git clone https://github.com/chef/ffi-libarchive.git /tmp/ffi-libarchive")
      if Dir.exist?("/tmp/ffi-libarchive")
        Dir.chdir("/tmp/ffi-libarchive") do
          if system("gem build ffi-libarchive.gemspec") && 
             system("gem install ffi-libarchive-*.gem --conservative --minimal-deps --no-document --force")
            puts "Successfully installed ffi-libarchive from source"
            gem_found = true
          else
            puts "Failed to build and install ffi-libarchive from source"
          end
        end
      end
    end
  end
  
  # Continue with normal processing if not already handled
  unless gem_found
    Dir["#{gem_home}/bundler/gems/*"].each do |gempath|
      if File.basename(gempath).start_with?("#{gem_base_name}-")
        gem_found = true
        puts "Found #{gem_base_name} at path: #{gempath}"
        install_platform_specific_gem(gempath, gem_base_name)
        break # Only process the first matching directory for each gem
      end
    end
  end
  
  unless gem_found
    puts "Warning: Could not find #{gem_base_name} in bundler gems directory"
    # Attempt to find the gem elsewhere
    puts "Searching for #{gem_base_name} in bundler cache..."
    cache_paths = Dir["#{gem_home}/cache/#{gem_base_name}-*.gem"]
    if !cache_paths.empty?
      puts "Found #{gem_base_name} in cache: #{cache_paths.first}"
      # Install directly from cache
      system("gem install #{cache_paths.first} --conservative --minimal-deps --no-document --force") or 
        puts "Failed to install #{gem_base_name} from cache"
    else
      puts "Attempting to install #{gem_base_name} directly from rubygems..."
      system("gem install #{gem_base_name} --conservative --minimal-deps --no-document --force") or 
        puts "Failed to install #{gem_base_name} from rubygems"
    end
  end
end

# Final verification step
platform_specific_gems.each do |gem_name|
  puts "Verifying #{gem_name} installation..."
  installed = system("gem list -i #{gem_name} > /dev/null 2>&1")
  if installed
    puts "✓ #{gem_name} is properly installed"
    
    # For ffi-libarchive, do an extra check to ensure it's properly linked
    if gem_name == "ffi-libarchive"
      puts "Checking #{gem_name} path and availability..."
      gem_path = `gem which #{gem_name} 2>/dev/null`.strip
      if gem_path && !gem_path.empty?
        puts "  - Found at: #{gem_path}"
        # Create a simple test file to verify it works
        test_file = "/tmp/test_ffi_libarchive.rb"
        File.write(test_file, "require '#{gem_name}'; puts 'Successfully required #{gem_name}'")
        if system("ruby #{test_file}")
          puts "  - Gem is properly linked and working"
        else
          puts "  - ⚠ WARNING: Gem is installed but cannot be required"
          # Try creating a symlink to make the gem more discoverable
          puts "  - Attempting to fix by linking the gem..."
          gem_dir = gem_path.split('/lib/')[0]
          target_dir = "#{gem_home}/gems/ffi-libarchive-1.2.0"
          unless Dir.exist?(target_dir)
            puts "  - Creating directory: #{target_dir}"
            FileUtils.mkdir_p(target_dir) rescue nil
            if Dir.exist?(gem_dir)
              # Copy files to ensure proper installation
              system("cp -R #{gem_dir}/* #{target_dir}/") rescue nil
              puts "  - Files copied to expected location"
            end
          end
        end
      else
        puts "  - ⚠ WARNING: Could not determine gem path"
      end
    end
  else
    puts "⚠ #{gem_name} appears to be missing or improperly installed"
    if gem_name == "ffi-libarchive"
      puts "Attempting final emergency installation of #{gem_name}..."
      system("gem install #{gem_name} -v 1.2.0 --force --no-document")
    end
  end
end
