#!/usr/bin/env ruby
# Removes stray Gemfile.lock shipped inside the lint_roller gem to appease scanners.
require "rubygems"

def cleanup_lint_roller_lockfile
  puts "Cleaning up lint_roller Gemfile.lock..."
  specs = Gem::Specification.find_all_by_name("lint_roller")
  if specs.empty?
    puts "  No lint_roller gem installed"
    return
  end

  specs.each do |spec|
    gemfile_lock_path = File.join(spec.gem_dir, "Gemfile.lock")
    if File.exist?(gemfile_lock_path)
      puts "  Removing #{gemfile_lock_path}"
      File.delete(gemfile_lock_path)
      puts "  Successfully removed lint_roller Gemfile.lock"
    else
      puts "  No Gemfile.lock found in #{spec.gem_dir}"
    end
  end
rescue StandardError => e
  warn "  Warning: Failed to clean up lint_roller Gemfile.lock: #{e.message}"
end

cleanup_lint_roller_lockfile
