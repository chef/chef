#!/usr/bin/env ruby

gem_home = Gem.paths.home

puts "fixing bundle installed gems in #{gem_home}"

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
  next if %w{chef chef-universal-mingw-ucrt proxifier}.include?(gem_name)

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
