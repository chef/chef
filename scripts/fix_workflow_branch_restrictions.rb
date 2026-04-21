#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to ensure all GitHub workflows with pull_request_target have branch restrictions
# Usage: ruby scripts/fix_workflow_branch_restrictions.rb [--dry-run]

require "yaml"
require "fileutils"

class WorkflowBranchRestrictionFixer
  WORKFLOWS_DIR = ".github/workflows"
  TARGET_BRANCH = "main"

  def initialize(dry_run: false)
    @dry_run = dry_run
    @fixed_files = []
    @already_correct = []
    @no_prt = []
  end

  def run
    workflow_files = Dir.glob(File.join(WORKFLOWS_DIR, "*.yml"))

    puts "Scanning #{workflow_files.length} workflow files..."
    puts "Mode: #{@dry_run ? 'DRY RUN' : 'APPLY CHANGES'}"
    puts "-" * 80

    workflow_files.each do |file|
      process_workflow(file)
    end

    print_summary
  end

  private

  def process_workflow(file)
    content = File.read(file)

    # Check if file has pull_request_target
    unless content.match?(/pull_request_target/)
      @no_prt << file
      return
    end

    # Parse YAML to check structure
    begin
      data = YAML.safe_load(content, permitted_classes: [Symbol], aliases: true)
    rescue => e
      puts "⚠️  Error parsing #{file}: #{e.message}"
      return
    end

    # The key "on" might be parsed as different things:
    # - "on" (string)
    # - :on (symbol)
    # - true (boolean, because "on" is a YAML keyword)
    # - "\"on\"" (quoted in YAML)
    on_config = data["on"] || data[:on] || data[true] || data["\"on\""]

    # Handle different formats of pull_request_target
    has_prt = false
    needs_fix = false

    if on_config.is_a?(Array)
      # Format: on: ['pull_request_target']
      has_prt = on_config.include?("pull_request_target") || on_config.include?(:pull_request_target)
      needs_fix = has_prt # Array format can't have branch restrictions inline
    elsif on_config.is_a?(String)
      # Format: on: pull_request_target (parsed as on: "pull_request_target")
      has_prt = on_config == "pull_request_target"
      needs_fix = has_prt
    elsif on_config.is_a?(Hash)
      prt_config = on_config["pull_request_target"] || on_config[:pull_request_target]
      # Check if pull_request_target key exists (even if value is nil)
      has_prt = on_config.key?("pull_request_target") || on_config.key?(:pull_request_target)

      if has_prt
        # Check if branches restriction exists
        if prt_config.is_a?(Hash)
          branches = prt_config["branches"] || prt_config[:branches]
          has_main_branch = branches.is_a?(Array) && branches.include?(TARGET_BRANCH)
          needs_fix = !has_main_branch
        else
          # pull_request_target: with no config (nil value)
          needs_fix = true
        end
      end
    end

    if has_prt && needs_fix
      fix_workflow(file, content, on_config)
    elsif has_prt
      @already_correct << file
      puts "✓ #{file} - already has branch restriction"
    end
  end

  def fix_workflow(file, content, on_config)
    puts "#{@dry_run ? '🔍' : '🔧'} Fixing #{file}..."

    # Strategy: Use text manipulation to preserve formatting and comments
    new_content = content.dup

    # Pattern 1: pull_request_target: with empty or no value (most common)
    # Matches: "  pull_request_target:" followed by optional whitespace/newline
    if new_content =~ /^(\s*)pull_request_target:\s*$/m
      indent = $1
      # Add branches configuration right after pull_request_target:
      replacement = "#{indent}pull_request_target:\n#{indent}  branches:\n#{indent}    - #{TARGET_BRANCH}"
      new_content.sub!(/^(\s*)pull_request_target:\s*$/, replacement)
      apply_fix(file, new_content)
      return
    end

    # Pattern 2: on: pull_request_target (inline, simple format)
    if new_content =~ /^(\s*)on:\s+pull_request_target\s*$/
      indent = $1
      # Convert to block format with branches
      replacement = "#{indent}on:\n#{indent}  pull_request_target:\n#{indent}    branches:\n#{indent}      - #{TARGET_BRANCH}"
      new_content.sub!(/^(\s*)on:\s+pull_request_target\s*$/, replacement)
      apply_fix(file, new_content)
      return
    end

    # Pattern 3: Array format on: - 'pull_request_target'
    # Match the "on:" followed by "  - 'pull_request_target'" pattern
    if new_content =~ /^(\s*)on:\s*\n\s*-\s+['"]?pull_request_target['"]?\s*$/m
      indent = $1
      replacement = "#{indent}on:\n#{indent}  pull_request_target:\n#{indent}    branches:\n#{indent}      - #{TARGET_BRANCH}"
      new_content.sub!(/^(\s*)on:\s*\n\s*-\s+['"]?pull_request_target['"]?\s*$/m, replacement)
      apply_fix(file, new_content)
      return
    end

    puts "⚠️  #{file} - Could not automatically fix. Manual intervention needed."
    puts "   Current 'on' config: #{on_config.inspect}"
  end

  def apply_fix(file, new_content)
    if @dry_run
      puts "   Would update file (dry run mode)"
      @fixed_files << file
    else
      File.write(file, new_content)
      puts "   ✓ Updated file"
      @fixed_files << file
    end
  end

  def print_summary
    puts "\n" + "=" * 80
    puts "SUMMARY"
    puts "=" * 80

    if @fixed_files.any?
      puts "\n✓ Fixed #{@fixed_files.length} file(s):"
      @fixed_files.each { |f| puts "  - #{f}" }
    end

    if @already_correct.any?
      puts "\n✓ Already correct (#{@already_correct.length} file(s)):"
      @already_correct.each { |f| puts "  - #{f}" }
    end

    if @no_prt.any?
      puts "\nℹ️  No pull_request_target (#{@no_prt.length} file(s)) - skipped"
    end

    if @fixed_files.any? && @dry_run
      puts "\n" + "⚠️  " * 20
      puts "This was a DRY RUN. No files were modified."
      puts "Run without --dry-run to apply changes."
      puts "⚠️  " * 20
    end

    puts "\n✓ Done!"
  end
end

# Main execution
dry_run = ARGV.include?("--dry-run")

if ARGV.include?("--help") || ARGV.include?("-h")
  puts "Usage: ruby scripts/fix_workflow_branch_restrictions.rb [--dry-run]"
  puts ""
  puts "Ensures all GitHub workflows with pull_request_target have branch restrictions."
  puts ""
  puts "Options:"
  puts "  --dry-run    Show what would be changed without modifying files"
  puts "  --help, -h   Show this help message"
  exit 0
end

fixer = WorkflowBranchRestrictionFixer.new(dry_run: dry_run)
fixer.run
