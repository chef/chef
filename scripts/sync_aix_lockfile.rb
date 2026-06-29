#!/usr/bin/env ruby
#
# scripts/sync_aix_lockfile.rb
#
# Copies the current Gemfile.lock to Gemfile-aix.lock.erb, then:
#   1. Strips Windows-platform binary gem variants (e.g. ffi-1.16.3-x64-mingw-ucrt)
#   2. Removes Windows-only gem specs entirely (win32-*, chef-powershell, etc.)
#   3. Removes the Windows-specific chef variant PATH spec
#   4. Cleans the PLATFORMS section to only include AIX-relevant platforms
#   5. Re-applies pinned AIX overrides from scripts/aix_gem_pins.yml
#   6. Replaces path gem versions (chef, chef-bin, chef-config, chef-utils) with
#      an ERB placeholder (<%= version %>) so the lockfile stays valid across
#      Expeditor version bumps without manual edits.
#
# The generated Gemfile-aix.lock.erb is committed. At omnibus build time,
# chef-local-source.rb renders it to Gemfile-aix.lock (gitignored).
#
# Run this after any update to Gemfile.lock and commit Gemfile-aix.lock.erb.
#
# Usage:
#   ruby scripts/sync_aix_lockfile.rb

require "set"
require "yaml"

REPO_ROOT = File.expand_path("..", __dir__)

pins_config_path = File.join(REPO_ROOT, "scripts", "aix_gem_pins.yml")
AIX_PINS =
  if File.exist?(pins_config_path)
    YAML.load_file(pins_config_path).fetch("gems", []).to_h { |e| [e.fetch("name"), e.fetch("version")] }
  else
    {}
  end.freeze

# Gems that exist only to support Windows and have no purpose on AIX.
WINDOWS_ONLY_GEMS = Set.new(%w{
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
}).freeze

# Platform suffixes whose binary-gem variants should be stripped entirely.
STRIP_PLATFORM_SUFFIXES = %w{
  x64-mingw-ucrt
  universal-mingw-ucrt
  universal-mingw32
  arm64-darwin
  x86_64-darwin
}.freeze

# Entries to remove from the PLATFORMS section.
REMOVE_PLATFORMS = %w{
  x64-mingw-ucrt
  arm64-darwin-21
  arm64-darwin
  x86_64-darwin
}.freeze

# ── Spec-block removal (line-by-line, no nested quantifiers) ─────────────────
# Walks the lockfile lines and drops any spec block that should not appear in
# the AIX lockfile: Windows-only gem names, Windows platform binary variants,
# and the universal-mingw-ucrt chef variant.
def remove_windows_specs(lines)
  result = []
  skipping = false

  lines.each do |line|
    if (m = line.match(/^    (\S+) \((.*?)\)\s*$/))
      gem_name   = m[1]
      version    = m[2] # may include platform, e.g. "1.16.3-x64-mingw-ucrt"

      windows_name     = WINDOWS_ONLY_GEMS.include?(gem_name)
      windows_platform = STRIP_PLATFORM_SUFFIXES.any? { |sfx| version.end_with?("-#{sfx}") }
      windows_chef     = gem_name == "chef" && version.end_with?("-universal-mingw-ucrt")

      skipping = windows_name || windows_platform || windows_chef
    elsif skipping && !line.start_with?("      ")
      skipping = false
    end

    result << line unless skipping
  end
  result
end

lines = File.readlines(File.join(REPO_ROOT, "Gemfile.lock"))

# ── 1–3. Remove Windows specs (PATH variants, binary platforms, Windows gems) ─
lines = remove_windows_specs(lines)

# ── 4. Update PLATFORMS section ──────────────────────────────────────────────
lines.reject! { |l| REMOVE_PLATFORMS.any? { |p| l.strip == p } }

# Ensure powerpc-aix-7 is present in PLATFORMS.
unless lines.any? { |l| l.strip == "powerpc-aix-7" }
  idx = lines.index { |l| l.strip == "PLATFORMS" }
  lines.insert(idx + 1, "  powerpc-aix-7\n") if idx
end

content = lines.join

# ── 5. Apply AIX gem version pins ────────────────────────────────────────────
AIX_PINS.each do |gem_name, version|
  content.gsub!(/^    #{Regexp.escape(gem_name)} \(\S+\)/, "    #{gem_name} (#{version})")
end

# ── 6. Replace path gem versions with ERB placeholder ────────────────────────
# Reads the current version from VERSION so the substitution works regardless
# of which Expeditor bump is current. The rendered Gemfile-aix.lock.erb uses
# <%= version %> which is evaluated at omnibus build time.
current_version = File.read(File.join(REPO_ROOT, "VERSION")).strip
PATH_GEMS = %w{chef chef-bin chef-config chef-utils}.freeze
PATH_GEMS.each do |gem_name|
  # Match "gem_name (VERSION)" and "gem_name (= VERSION)" in spec blocks
  content.gsub!(/(\b#{Regexp.escape(gem_name)} \((?:= )?)#{Regexp.escape(current_version)}(\))/) do
    "#{$1}<%= version %>#{$2}"
  end
end

output_path = File.join(REPO_ROOT, "Gemfile-aix.lock.erb")
File.write(output_path, content)
puts "Gemfile-aix.lock.erb updated from Gemfile.lock."
puts "Diff it with git before committing:"
puts "  git diff Gemfile-aix.lock.erb"
