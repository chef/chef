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

  next unless gem_name

  next if gem_name == "chef" || gem_name == "chef-universal-mingw32"

  puts "re-installing #{gem_name}..."

  Dir.chdir(gempath) do
    system("gem build #{gem_name}.gemspec") or raise "gem build failed"
    system("gem install #{gem_name}*.gem --conservative --minimal-deps --no-document") or raise "gem install failed"
  end
end
