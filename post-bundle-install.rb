#!/usr/bin/env ruby

gem_home = Gem.paths.home

puts "fixing bundle installed gems in #{gem_home}"

# Install gems from git repos.  This makes the assumption that there is a <gem_name>.gemspec and
# you can simply gem build + gem install the resulting gem, so nothing fancy.  This does not use
# rake install since we need --conservative --minimal-deps in order to not install duplicate gems.
#
Dir["#{gem_home}/bundler/gems/*"].each do |gempath|
  matches = File.basename(gempath).match(/(.*)-[A-Fa-f0-9]{12}/)
  next unless matches

  gem_name = matches[1]
  next unless gem_name

  next if gem_name == "chef"

  puts "re-installing #{gem_name}..."

  # we can't use "command" or "bundle" or "gem" DSL methods here since those are lazy and we need to run commands immediately
  # (this is like a shell_out inside of a ruby_block in core chef, you don't use an execute resource inside of a ruby_block or
  # things get really weird and unexpected)
  Dir.chdir(gempath) do
    system("gem build #{gem_name}.gemspec") or raise "gem build failed"
    system("gem install #{gem_name}*.gem --conservative --minimal-deps --no-document") or raise "gem install failed"
  end
end
