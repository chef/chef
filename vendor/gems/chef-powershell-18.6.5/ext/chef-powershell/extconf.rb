# frozen_string_literal: true
#
# Author:: John McCrae (<john.mccrae@progress.com>)
# Copyright:: Copyright, Chef Software Inc.
# Copyright:: Copyright, Progress Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Post-install extension to copy required DLL files to Chef's embedded bin directory.
# This ensures that the PowerShell wrapper DLLs are available to Chef even when
# chef-powershell gem is updated independently of Chef releases.
#

require "fileutils"
require "rbconfig"

# Only run on Windows platforms
if RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/

  # Required DLL files that must be present in chef\embedded\bin
  REQUIRED_DLLS = [
    "vcruntime140.dll",
    "vcruntime140_1.dll",
    "ijwhost.dll",
    "msvcp140.dll",
  ].freeze

  def log(message)
    puts "[chef-powershell] #{message}"
  end

  def find_chef_embedded_bin
    # Use RbConfig to find the embedded bin directory
    # This works because Chef installs gems into its embedded Ruby
    embedded_bin_path = RbConfig::CONFIG["bindir"]

    # Verify the path exists and normalize it
    if embedded_bin_path && File.directory?(embedded_bin_path)
      return embedded_bin_path.tr("\\", "/")
    end

    nil
  end

  def find_source_dlls
    # Look for DLLs in the gem's bin directory structure
    # They should be in bin/ruby_bin_folder/AMD64/
    gem_bin_dir = File.expand_path("../../bin", __dir__)

    possible_locations = [
      File.join(gem_bin_dir, "ruby_bin_folder", "AMD64"),
      gem_bin_dir,
    ]

    possible_locations.each do |location|
      if File.directory?(location)
        # Check if at least one required DLL exists here
        if REQUIRED_DLLS.any? { |dll| File.exist?(File.join(location, dll)) }
          return location
        end
      end
    end

    nil
  end

  def file_needs_update?(source, dest)
    return true unless File.exist?(dest)

    # Compare file sizes and modification times
    source_stat = File.stat(source)
    dest_stat = File.stat(dest)

    # Update if sizes differ or source is newer
    source_stat.size != dest_stat.size || source_stat.mtime > dest_stat.mtime
  end

  def install_dlls
    log "Checking for required PowerShell DLL files..."

    # Find the Chef embedded bin directory
    target_dir = find_chef_embedded_bin

    unless target_dir
      log "WARNING: Could not locate Chef embedded bin directory."
      log "DLL files will not be installed automatically."
      log "If you are using Chef, please ensure the following DLLs are in chef/embedded/bin:"
      REQUIRED_DLLS.each { |dll| log "  - #{dll}" }
      return
    end

    log "Found Chef embedded bin directory: #{target_dir}"

    # Find source DLLs
    source_dir = find_source_dlls

    unless source_dir
      log "WARNING: Could not locate source DLL files in gem installation."
      log "Expected location: bin/ruby_bin_folder/AMD64/"
      log "DLL files will not be installed."
      return
    end

    log "Found source DLLs in: #{source_dir}"

    # Copy each required DLL if present and needs updating
    installed = []
    updated = []
    missing = []
    skipped = []

    REQUIRED_DLLS.each do |dll|
      source_file = File.join(source_dir, dll)
      dest_file = File.join(target_dir, dll)

      unless File.exist?(source_file)
        missing << dll
        next
      end

      begin
        if File.exist?(dest_file)
          if file_needs_update?(source_file, dest_file)
            FileUtils.cp(source_file, dest_file, preserve: true)
            updated << dll
            log "Updated: #{dll}"
          else
            skipped << dll
          end
        else
          FileUtils.cp(source_file, dest_file, preserve: true)
          installed << dll
          log "Installed: #{dll}"
        end
      rescue => e
        log "ERROR: Failed to copy #{dll}: #{e.message}"
      end
    end

    # Summary
    log "Installation complete:"
    log "  - Newly installed: #{installed.length}" unless installed.empty?
    log "  - Updated: #{updated.length}" unless updated.empty?
    log "  - Already up-to-date: #{skipped.length}" unless skipped.empty?
    log "  - Missing from source: #{missing.length}" unless missing.empty?

    if missing.any?
      log "WARNING: The following DLL files were not found in the gem:"
      missing.each { |dll| log "  - #{dll}" }
    end
  end

  begin
    install_dlls
  rescue => e
    log "ERROR: Post-install script failed: #{e.message}"
    log e.backtrace.join("\n") if ENV["DEBUG"]
  end

else
  puts "[chef-powershell] Skipping DLL installation (non-Windows platform)"
end

# Create a dummy Makefile to satisfy RubyGems extension mechanism
File.open("Makefile", "w") do |f|
  f.puts "# Dummy Makefile for chef-powershell post-install extension"
  f.puts "install:"
  f.puts "\t@echo 'No compilation needed'"
  f.puts "clean:"
  f.puts "\t@echo 'Nothing to clean'"
  f.puts "all:"
  f.puts "\t@echo 'Nothing to build'"
end
