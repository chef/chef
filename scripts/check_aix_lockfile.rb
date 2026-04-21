#!/usr/bin/env ruby
#
# scripts/check_aix_lockfile.rb
#
# CI drift checker for Gemfile-aix.lock.
# Validates that all version differences between Gemfile-aix.lock and
# Gemfile.lock are within the approved set defined in config/aix_gem_pins.yml.
#
# Also verifies that Windows-only gems have been removed and that the AIX
# platform is present in the PLATFORMS section.
#
# Usage:
#   ruby scripts/check_aix_lockfile.rb
#
# Exit codes:
#   0  All checks passed.
#   1  Unexpected divergences or structural problems found.

require "bundler"
require "yaml"
require "set"

REPO_ROOT = File.expand_path("..", __dir__)

MAIN_LOCK  = File.join(REPO_ROOT, "Gemfile.lock")
AIX_LOCK   = File.join(REPO_ROOT, "Gemfile-aix.lock")
PINS_FILE  = File.join(REPO_ROOT, "scripts", "aix_gem_pins.yml")

WINDOWS_ONLY_GEMS = %w{
  chef-powershell
  ffi-win32-extensions
  iso8601
  structured_warnings
  win32-api
  win32-certstore
  win32-event
  win32-eventlog
  win32-ipc
  win32-mmap
  win32-mutex
  win32-process
  win32-service
  win32-taskscheduler
}.freeze

STRIP_PLATFORM_PATTERNS = [
  /-x64-mingw-ucrt$/,
  /-universal-mingw-ucrt$/,
  /-universal-mingw32$/,
].freeze

errors = []
warnings = []

# ── Existence checks ─────────────────────────────────────────────────────────
unless File.exist?(AIX_LOCK)
  warn "ERROR: Gemfile-aix.lock does not exist."
  warn "Run:  ruby scripts/sync_aix_lockfile.rb"
  exit 1
end

unless File.exist?(MAIN_LOCK)
  warn "ERROR: Gemfile.lock does not exist."
  exit 1
end

pins_config = File.exist?(PINS_FILE) ? YAML.load_file(PINS_FILE) : { "gems" => [] }
APPROVED_PINS = pins_config.fetch("gems", []).to_h { |e| [e.fetch("name"), e.fetch("version")] }.freeze

# ── Parse both lockfiles ──────────────────────────────────────────────────────
main_parsed = Bundler::LockfileParser.new(File.read(MAIN_LOCK))
aix_parsed  = Bundler::LockfileParser.new(File.read(AIX_LOCK))

main_specs = main_parsed.specs.reject { |s| STRIP_PLATFORM_PATTERNS.any? { |p| s.platform.to_s.match?(p) } }
aix_specs  = aix_parsed.specs.reject  { |s| STRIP_PLATFORM_PATTERNS.any? { |p| s.platform.to_s.match?(p) } }

main_versions = main_specs.to_h { |s| [s.name, s.version.to_s] }
aix_versions  = aix_specs.to_h  { |s| [s.name, s.version.to_s] }

# ── Check: Windows-only gems must not appear in AIX lockfile ─────────────────
WINDOWS_ONLY_GEMS.each do |gem_name|
  if aix_versions.key?(gem_name)
    errors << "Windows-only gem '#{gem_name}' found in Gemfile-aix.lock; run sync_aix_lockfile.rb to remove it."
  end
end

# ── Check: Windows platform binary variants must not appear ──────────────────
aix_parsed.specs.each do |spec|
  if STRIP_PLATFORM_PATTERNS.any? { |p| spec.platform.to_s.match?(p) }
    errors << "Windows platform binary '#{spec.name} (#{spec.version}-#{spec.platform})' found in Gemfile-aix.lock."
  end
end

# ── Check: AIX platform must be present ──────────────────────────────────────
aix_content = File.read(AIX_LOCK)
unless aix_content.match?(/^  powerpc-aix-7$/)
  errors << "PLATFORMS section in Gemfile-aix.lock is missing 'powerpc-aix-7'."
end

# ── Check: version divergences must be approved ───────────────────────────────
# Gems in main but not in AIX (expected: Windows-only gems)
missing_from_aix = main_versions.keys - aix_versions.keys
unexpected_missing = missing_from_aix.reject { |g| WINDOWS_ONLY_GEMS.include?(g) || APPROVED_PINS.key?(g) }
unexpected_missing.each do |gem_name|
  errors << "Gem '#{gem_name}' is in Gemfile.lock but missing from Gemfile-aix.lock without approval."
end

# Gems with different versions
version_divergences = aix_versions.select do |name, ver|
  main_versions.key?(name) && main_versions[name] != ver
end

version_divergences.each do |gem_name, aix_ver|
  main_ver = main_versions[gem_name]
  if APPROVED_PINS.key?(gem_name)
    approved_ver = APPROVED_PINS[gem_name]
    if aix_ver != approved_ver
      errors << "Gem '#{gem_name}' is pinned to #{aix_ver} in Gemfile-aix.lock but config/aix_gem_pins.yml says #{approved_ver}."
    else
      puts "  OK  #{gem_name}: #{aix_ver} (approved AIX pin; main has #{main_ver})"
    end
  else
    errors << "Gem '#{gem_name}' differs: Gemfile.lock=#{main_ver}, Gemfile-aix.lock=#{aix_ver} — not in approved pin list."
  end
end

# Gems in AIX but not in main (unexpected additions)
extra_in_aix = aix_versions.keys - main_versions.keys
extra_in_aix.each do |gem_name|
  errors << "Gem '#{gem_name}' is in Gemfile-aix.lock but not in Gemfile.lock."
end

# ── Report ────────────────────────────────────────────────────────────────────
warnings.each { |w| warn "WARN: #{w}" }

if errors.empty?
  puts "Gemfile-aix.lock divergences are within the approved set."
  exit 0
else
  errors.each { |e| warn "ERROR: #{e}" }
  warn "\nGemfile-aix.lock has #{errors.size} unapproved divergence(s)."
  warn "Run:  ruby scripts/sync_aix_lockfile.rb"
  exit 1
end
