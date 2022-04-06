#
# Copyright:: Copyright (c) Chef Software Inc.
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

def add_libarchive_dll_directory
  require "ruby_installer"
  libarchive_paths = Dir.glob("{#{Gem.dir},C:/hab}/**/libarchive.dll").map { |f| File.expand_path(f) }
  if libarchive_paths.empty?
    $stderr.puts <<~EOL
      !!!!
        We couldn't find a libarchive.dll in #{Gem.dir} or C:/hab

        If this is running in a CI/CD environment, this may end up causing failures
        in the tests for archive_file. If this is not running in a CI/CD
        environment then it may be safe to ignore this. That is especially true if
        you're not using the Ruby Installer as your Ruby runtime.
      !!!!
    EOL
    return
  end

  $stderr.puts "\nFound the following libarchive paths:\n\n#{libarchive_paths.map { |f| "- #{f}\n" }.join}\n\n"
  libarchive_path = libarchive_paths.first
  libarchive_dir = File.dirname(libarchive_path)

  if defined?(RubyInstaller::Build) && RubyInstaller::Build.methods.include?(:add_dll_directory)
    $stderr.puts "Adding #{libarchive_dir} as a DLL load path using RubyInstaller::Build#add_dll_directory"
    RubyInstaller::Build.add_dll_directory(libarchive_dir)
  elsif defined?(RubyInstaller::Runtime) && RubyInstaller::Runtime.methods.include?(:add_dll_directory)
    $stderr.puts "Adding #{libarchive_dir} as a DLL load path using RubyInstaller::Runtime#add_dll_directory"
    RubyInstaller::Runtime.add_dll_directory(libarchive_dir)
  else
    $stderr.puts "Unable to find the right namespace to call #add_dll_directory! Please raise an issue on [GitHub](https://github.com/chef/chef/issues/new/choose)."
  end
rescue LoadError
  $stderr.puts "Failed to load ruby_installer. Assuming Ruby Installer is not being used."
end

add_libarchive_dll_directory if RUBY_PLATFORM.match?(/mswin|mingw32|windows/)
