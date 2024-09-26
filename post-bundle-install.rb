#!/usr/bin/env ruby

gem_home = Gem.paths.home

puts "fixing bundle installed gems in #{gem_home}"

# Install gems from git repos.  This makes the assumption that there is a <gem_name>.gemspec and
# you can simply gem build + gem install the resulting gem, so nothing fancy.  This does not use
# rake install since we need --conservative --minimal-deps in order to not install duplicate gems.
#
Dir["#{gem_home}/bundler/gems/*"].each do |gempath|
  puts "gempath is: #{gempath}"
  matches = File.basename(gempath).match(/.*-[A-Fa-f0-9]{12}/)
  next unless matches

  puts "files in gempath: #{Dir["#{gempath}/*"]}"
  puts "gemspec files in gempath: #{Dir["#{gempath}/*.gemspec"]}"

  # Output the gempath
  puts "gempath is: #{gempath}"

  # Find the gemspec file recursively in the gempath
  gemspec_files = Dir["#{gempath}/**/*.gemspec"]

  # Output the files found in gempath
  puts "Found the following files in gempath:"
  gemspec_files.each { |file| puts file }

  gem_name = nil
  # Ensure there is at least one gemspec file found
  if gemspec_files.any?
    gemspec_path = gemspec_files.first
    gem_name = File.basename(gemspec_path, ".gemspec")
    puts "First gemspec file found: #{gemspec_path}"
    puts "Gem name is: #{gem_name}"
  else
    puts "No gemspec file found in #{gempath}"
  end

  next unless gem_name

  # Check for excluded gem names
  next if %w{chef chef-universal-mingw-ucrt proxifier}.include?(gem_name)

  puts "Re-installing #{gem_name}..."

  # Change to the directory where the gemspec is located
  gemspec_directory = File.dirname(gemspec_files.first)

  Dir.chdir(gemspec_directory) do
    # Build and install the gem from the correct directory
    system("gem build #{File.basename(gemspec_path)}") or raise "gem build failed"
    system("gem install #{gem_name}*.gem --conservative --minimal-deps --no-document") or raise "gem install failed"
  end

end
