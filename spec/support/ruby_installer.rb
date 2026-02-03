#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

# Helper to verify that required runtime dependencies exist alongside a DLL
def verify_dependencies_for_dll(dll_dir, dll_name)
  required_runtimes = ["vcruntime140.dll", "msvcp140.dll"]

  missing_runtimes = required_runtimes.select do |runtime_dll|
    !File.exist?(File.join(dll_dir, runtime_dll))
  end

  if missing_runtimes.any?
    $stderr.puts "\n!!!!"
    $stderr.puts "CRITICAL ERROR: Missing required runtime dependencies for #{dll_name}"
    $stderr.puts "Location: #{dll_dir}"
    $stderr.puts "Missing DLLs: #{missing_runtimes.join(", ")}"
    $stderr.puts "\nThis will cause PowerShell tests to fail or behave unexpectedly."
    $stderr.puts "!!!!\n"
    return false
  end

  true
end

def load_dlls(match_path, is_powershell_dll = false)
  require "ruby_installer"
  matched_paths = Dir.glob("{#{Gem.dir},C:/hab}/**/#{match_path}").map { |f| File.expand_path(f) }
  if matched_paths.empty?
    error_msg = <<~EOL
      !!!!
        We couldn't find any matches for #{match_path} in #{Gem.dir} or C:/hab

        If this is running in a CI/CD environment, this will cause test failures.
        If this is not running in a CI/CD environment then it may be safe to ignore this
        (only if you're not using the Ruby Installer as your Ruby runtime).
      !!!!
    EOL
    $stderr.puts error_msg

    # For PowerShell DLL, this is a critical error - fail fast
    if is_powershell_dll
      raise "CRITICAL: Chef.PowerShell.dll not found - PowerShell tests will fail"
    end

    return
  end

  $stderr.puts "\nFound the following dll paths:\n\n#{matched_paths.map { |f| "- #{f}\n" }.join}\n\n"
  dll_path = matched_paths.first
  dll_dir = File.dirname(dll_path)
  dll_name = File.basename(dll_path)

  # For PowerShell DLL, verify runtime dependencies are present
  if is_powershell_dll && !verify_dependencies_for_dll(dll_dir, dll_name)
    raise "CRITICAL: Required runtime DLLs missing for PowerShell - tests will fail"
  end

  if defined?(RubyInstaller::Build) && RubyInstaller::Build.methods.include?(:add_dll_directory)
    $stderr.puts "Adding #{dll_dir} as a DLL load path using RubyInstaller::Build#add_dll_directory"
    RubyInstaller::Build.add_dll_directory(dll_dir)
  elsif defined?(RubyInstaller::Runtime) && RubyInstaller::Runtime.methods.include?(:add_dll_directory)
    $stderr.puts "Adding #{dll_dir} as a DLL load path using RubyInstaller::Runtime#add_dll_directory"
    RubyInstaller::Runtime.add_dll_directory(dll_dir)
  else
    $stderr.puts "WARNING: Unable to find the right namespace to call #add_dll_directory!"
    $stderr.puts "Please raise an issue on GitHub: https://github.com/chef/chef/issues/new/choose"
  end
rescue LoadError
  $stderr.puts "Failed to load ruby_installer. Assuming Ruby Installer is not being used."
end

if RUBY_PLATFORM.match?(/mswin|mingw|windows/)
  load_dlls("libarchive.dll", false)
  load_dlls("bin/ruby_bin_folder/#{ENV["PROCESSOR_ARCHITECTURE"]}/Chef.PowerShell.dll", true)
end
