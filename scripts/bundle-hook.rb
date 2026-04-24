#!/usr/bin/env ruby
# Bundle hook script to generate both standard and AIX-specific lock files
# This script runs bundle install/update twice:
# 1. Normal run to generate Gemfile.lock
# 2. AIX-specific run with ENV["GENERATE_AIX"] = true to generate Gemfile-aix.lock

require "fileutils"

GEMFILE_LOCK = "Gemfile.lock".freeze
GEMFILE_AIX_LOCK = "Gemfile.aix.lock".freeze
GEMFILE_LOCK_BASE = "Gemfile.lock.base".freeze

# Parse command line arguments
command = ARGV[0] || "install"
bundle_args = ARGV[1..-1] || []

puts "🔧 Running bundle hook for command: #{command}"
puts "📦 Additional arguments: #{bundle_args.join(" ")}" unless bundle_args.empty?

# Ensure we're in the project root
project_root = File.expand_path("..", __dir__)
Dir.chdir(project_root) do

  # Step 1: Run normal bundle operation
  puts "\n📋 Step 1: Running normal bundle #{command}..."
  normal_cmd = "bundle #{command} #{bundle_args.join(" ")}"
  puts "   Command: #{normal_cmd}"

  unless system(normal_cmd)
    puts "❌ Normal bundle #{command} failed!"
    exit 1
  end

  # Step 2: Copy Gemfile.lock to Gemfile.lock.base
  puts "\n💾 Step 2: Backing up #{GEMFILE_LOCK} to #{GEMFILE_LOCK_BASE}..."
  if File.exist?(GEMFILE_LOCK)
    FileUtils.cp(GEMFILE_LOCK, GEMFILE_LOCK_BASE)
    puts "   ✅ #{GEMFILE_LOCK} copied to #{GEMFILE_LOCK_BASE}"
  else
    puts "   ⚠️  No #{GEMFILE_LOCK} found to backup"
  end

  # Step 3: Run AIX-specific bundle operation
  puts "\n🖥️  Step 3: Running AIX-specific bundle #{command}..."
  aix_env = ENV.to_h.merge("GENERATE_AIX" => "true")
  aix_cmd = "bundle #{command} #{bundle_args.join(" ")}"
  puts "   Command: #{aix_cmd} (with GENERATE_AIX=true)"

  unless system(aix_env, aix_cmd)
    puts "❌ AIX bundle #{command} failed!"

    # Restore original Gemfile.lock on failure
    if File.exist?(GEMFILE_LOCK_BASE)
      puts "🔄 Restoring original #{GEMFILE_LOCK}..."
      FileUtils.mv(GEMFILE_LOCK_BASE, GEMFILE_LOCK)
    end
    exit 1
  end

  # Step 4: Move AIX Gemfile.lock to Gemfile-aix.lock
  puts "\n📁 Step 4: Moving AIX #{GEMFILE_LOCK} to #{GEMFILE_AIX_LOCK}..."
  if File.exist?(GEMFILE_LOCK)
    FileUtils.mv(GEMFILE_LOCK, GEMFILE_AIX_LOCK)
    puts "   ✅ #{GEMFILE_LOCK} moved to #{GEMFILE_AIX_LOCK}"
  else
    puts "   ⚠️  No #{GEMFILE_LOCK} found from AIX run"
  end

  # Step 5: Restore original Gemfile.lock
  puts "\n🔄 Step 5: Restoring original #{GEMFILE_LOCK}..."
  if File.exist?(GEMFILE_LOCK_BASE)
    FileUtils.mv(GEMFILE_LOCK_BASE, GEMFILE_LOCK)
    puts "   ✅ #{GEMFILE_LOCK_BASE} restored to #{GEMFILE_LOCK}"
  else
    puts "   ⚠️  No #{GEMFILE_LOCK_BASE} found to restore"
  end

  puts "\n🎉 Bundle hook completed successfully!"
  puts "📄 Generated files:"
  puts "   - #{GEMFILE_LOCK} (standard dependencies)"
  puts "   - #{GEMFILE_AIX_LOCK} (AIX-specific dependencies)"

rescue => e
  puts "\n💥 Error during bundle hook execution: #{e.message}"

  # Cleanup: restore original lock file if it exists
  if File.exist?(GEMFILE_LOCK_BASE)
    puts "🧹 Cleaning up: restoring original #{GEMFILE_LOCK}..."
    FileUtils.mv(GEMFILE_LOCK_BASE, GEMFILE_LOCK)
  end

  exit 1

end
