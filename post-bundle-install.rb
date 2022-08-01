#!/usr/bin/env ruby

require 'fileutils'

gem_home = Gem.paths.home

puts "fixing bundle installed gems in #{gem_home}"

# Install gems from git repos.  This makes the assumption that there is a <gem_name>.gemspec and
# you can simply gem build + gem install the resulting gem, so nothing fancy.  This does not use
# rake install since we need --conservative --minimal-deps in order to not install duplicate gems.
#
Dir["#{gem_home}/bundler/gems/*"].each do |gempath|
  puts "===Gempath: #{gempath.inspect}"
  matches = File.basename(gempath).match(/.*-[A-Fa-f0-9]{12}/)
  next unless matches

  if gempath.match("chef-powershell")
    path = "#{gempath}/chef-powershell"
    
    #For now copy the windowspowershell dlls at chef/chef to gem here
    dll_files = Dir.glob(File.expand_path("distro/ruby_bin_folder/#{ENV["PROCESSOR_ARCHITECTURE"]}", __dir__) + "**/*")
    puts "=== dll files #{dll_files.inspect}"
    bin_path = "#{path}/bin/ruby_bin_folder/#{ENV["PROCESSOR_ARCHITECTURE"]}"
    puts "==== bin_path:#{bin_path}"

    FileUtils.mkdir_p "#{bin_path}"
    FileUtils.cp_r dll_files, bin_path

    puts "=== bin_path contents after copying: #{Dir[bin_path + '/*']}}"
  else  
    path = "#{gempath}" 
  end

  gem_name = File.basename(Dir["#{path}/*.gemspec"].first, ".gemspec")
  # FIXME: should strip any valid ruby platform off of the gem_name if it matches

  next unless gem_name

  # FIXME: should omit the gem which is in the current directory and not hard code chef
  next if %w{chef chef-universal-mingw32}.include?(gem_name)

  puts "re-installing #{gem_name}..."

  Dir.chdir(path) do
    system("gem build #{gem_name}.gemspec") or raise "gem build failed"
    system("gem install #{gem_name}*.gem --conservative --minimal-deps --no-document") or raise "gem install failed"
  end
end
