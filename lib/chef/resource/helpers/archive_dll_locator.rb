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
#

require "open3" unless defined?(Open3)

class Chef
  module ResourceHelpers
    # Locates archive.dll for a Habitat-packaged Chef on Windows. Sources are
    # tried from most to least authoritative so that a stray or older libarchive
    # package on the machine is only used when nothing more specific exists:
    #   1. RUBY_DLL_PATH (set by the Habitat plan)
    #   2. the hab CLI (`hab pkg path core/libarchive`)
    #   3. a search of the hab root derived from the location of chef itself
    module ArchiveDllLocator
      DLL_NAME = "archive.dll".freeze

      def self.find(source_file: __FILE__, env: ::ENV)
        from_ruby_dll_path(env) || from_hab_cli || from_hab_root_search(source_file)
      end

      def self.from_ruby_dll_path(env = ::ENV)
        env["RUBY_DLL_PATH"].to_s.split(::File::PATH_SEPARATOR).each do |dir|
          next if dir.empty?

          candidate = ::File.join(dir.tr("\\", "/"), DLL_NAME)
          return candidate if ::File.exist?(candidate)
        end
        nil
      end

      def self.from_hab_cli
        stdout, stderr, status = Open3.capture3("hab pkg path core/libarchive")
        unless status.success?
          Chef::Log.debug("Failed to determine Habitat libarchive path: #{stderr}")
          return nil
        end

        candidate = ::File.join(stdout.strip.tr("\\", "/"), "bin", DLL_NAME)
        return candidate if ::File.exist?(candidate)

        Chef::Log.debug("#{DLL_NAME} not found in Habitat path: #{candidate}")
        nil
      rescue SystemCallError => e
        Chef::Log.debug("hab CLI not available to locate libarchive: #{e.message}")
        nil
      end

      def self.from_hab_root_search(source_file)
        hab_root = source_file.tr("\\", "/")[%r{\A(.*?/hab)/pkgs/}, 1]
        return nil unless hab_root

        ::Dir.glob("#{hab_root}/pkgs/core/libarchive/*/*/bin/#{DLL_NAME}").max
      end
    end
  end
end
