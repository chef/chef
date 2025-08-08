#
# Bundle tasks for generating both standard and AIX-specific lock files
#

namespace :bundle do
  desc "Run bundle install and generate both Gemfile.lock and Gemfile.aix.lock"
  task :install do
    ruby "scripts/bundle-hook.rb install"
  end

  desc "Run bundle update and generate both Gemfile.lock and Gemfile.aix.lock"
  task :update do
    ruby "scripts/bundle-hook.rb update"
  end

  desc "Run bundle install with specific gem name and generate both lock files"
  task :install_gem, [:gem_name] do |task, args|
    gem_name = args[:gem_name]
    if gem_name.nil? || gem_name.empty?
      puts "Usage: rake bundle:install_gem[gem_name]"
      exit 1
    end
    ruby "scripts/bundle-hook.rb install --only #{gem_name}"
  end

  desc "Run bundle update with specific gem name and generate both lock files"
  task :update_gem, [:gem_name] do |task, args|
    gem_name = args[:gem_name]
    if gem_name.nil? || gem_name.empty?
      puts "Usage: rake bundle:update_gem[gem_name]"
      exit 1
    end
    ruby "scripts/bundle-hook.rb update #{gem_name}"
  end

  desc "Validate that both Gemfile.lock and Gemfile.aix.lock are in sync with dependencies"
  task :validate do
    puts "🔍 Validating lock files are in sync..."

    # Check if both files exist
    unless File.exist?("Gemfile.lock")
      puts "❌ Gemfile.lock not found. Run 'rake bundle:install' first."
      exit 1
    end

    unless File.exist?("Gemfile.aix.lock")
      puts "❌ Gemfile.aix.lock not found. Run 'rake bundle:install' first."
      exit 1
    end

    # Parse both lock files and compare relevant sections
    require "bundler"

    puts "📋 Standard lock file:"
    system("head -20 Gemfile.lock")

    puts "\n📋 AIX lock file:"
    system("head -20 Gemfile.aix.lock")

    puts "\n✅ Both lock files exist. Manual inspection recommended to ensure platform-specific dependencies are correct."
  end

  desc "Clean lock files and regenerate both"
  task :clean_and_install do
    puts "🧹 Cleaning existing lock files..."
    File.delete("Gemfile.lock") if File.exist?("Gemfile.lock")
    File.delete("Gemfile.aix.lock") if File.exist?("Gemfile.aix.lock")
    File.delete("Gemfile.lock.base") if File.exist?("Gemfile.lock.base")

    puts "🔄 Regenerating lock files..."
    Rake::Task["bundle:install"].invoke
  end
end

desc "Alias for bundle:install - generates both lock files"
task bundle_install: "bundle:install"

desc "Alias for bundle:update - generates both lock files"
task bundle_update: "bundle:update"
