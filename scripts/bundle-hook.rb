#!/usr/bin/env ruby
# Bundle hook script to generate both standard and AIX-specific lock files
# This script runs bundle install/update twice:
# 1. Normal run to generate Gemfile.lock
# 2. AIX-specific run with ENV["GENERATE_AIX"] = true to generate Gemfile-aix.lock

require "fileutils"

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
  puts "\n💾 Step 2: Backing up Gemfile.lock to Gemfile.lock.base..."
  if File.exist?("Gemfile.lock")
    FileUtils.cp("Gemfile.lock", "Gemfile.lock.base")
    puts "   ✅ Gemfile.lock copied to Gemfile.lock.base"
  else
    puts "   ⚠️  No Gemfile.lock found to backup"
  end

  # Step 3: Run AIX-specific bundle operation
  puts "\n🖥️  Step 3: Running AIX-specific bundle #{command}..."
  aix_env = ENV.to_h.merge("GENERATE_AIX" => "true")
  aix_cmd = "bundle #{command} #{bundle_args.join(" ")}"
  puts "   Command: #{aix_cmd} (with GENERATE_AIX=true)"

  unless system(aix_env, aix_cmd)
    puts "❌ AIX bundle #{command} failed!"

    # Restore original Gemfile.lock on failure
    if File.exist?("Gemfile.lock.base")
      puts "🔄 Restoring original Gemfile.lock..."
      FileUtils.mv("Gemfile.lock.base", "Gemfile.lock")
    end
    exit 1
  end

  # Step 4: Move AIX Gemfile.lock to Gemfile-aix.lock
  puts "\n📁 Step 4: Moving AIX Gemfile.lock to Gemfile-aix.lock..."
  if File.exist?("Gemfile.lock")
    FileUtils.mv("Gemfile.lock", "Gemfile-aix.lock")
    puts "   ✅ Gemfile.lock moved to Gemfile-aix.lock"
  else
    puts "   ⚠️  No Gemfile.lock found from AIX run"
  end

  # Step 5: Restore original Gemfile.lock
  puts "\n🔄 Step 5: Restoring original Gemfile.lock..."
  if File.exist?("Gemfile.lock.base")
    FileUtils.mv("Gemfile.lock.base", "Gemfile.lock")
    puts "   ✅ Gemfile.lock.base restored to Gemfile.lock"
  else
    puts "   ⚠️  No Gemfile.lock.base found to restore"
  end

  puts "\n🎉 Bundle hook completed successfully!"
  puts "📄 Generated files:"
  puts "   - Gemfile.lock (standard dependencies)"
  puts "   - Gemfile-aix.lock (AIX-specific dependencies)"

rescue => e
  puts "\n💥 Error during bundle hook execution: #{e.message}"

  # Cleanup: restore original lock file if it exists
  if File.exist?("Gemfile.lock.base")
    puts "🧹 Cleaning up: restoring original Gemfile.lock..."
    FileUtils.mv("Gemfile.lock.base", "Gemfile.lock")
  end

  exit 1

end
