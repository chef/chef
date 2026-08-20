# frozen_string_literal: true
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

require_relative "../internal"
require_relative "platform_family"

module ChefUtils
  module DSL
    module DefaultPaths
      include Internal

      # @since 15.5
      def default_paths(env = nil)
        env_path = env ? env["PATH"] : __env_path
        env_path = "" if env_path.nil?
        path_separator = ChefUtils.windows? ? ";" : ":"
        # ensure the Ruby and Gem bindirs are included for packaged chef installs (e.g., habitat)
        new_paths = env_path.split(path_separator)
        [ __ruby_bindir, __gem_bindir ].compact.each do |path|
          new_paths = [ path ] + new_paths unless new_paths.include?(path)
        end
        __default_paths.each do |path|
          new_paths << path unless new_paths.include?(path)
        end
        new_paths.join(path_separator).encode("utf-8", invalid: :replace, undef: :replace)
      end

      private

      def __default_paths
        if ChefUtils.windows?
          # On Windows with Habitat-based packaging (Chef 19+), the Habitat launcher
          # overwrites the process PATH with only the package's bin dirs, stripping
          # standard Windows system directories. We restore them here using SystemRoot
          # (an OS-level env var set by Windows itself, always present and unaffected
          # by Habitat's PATH overwrite), mirroring what Linux already does for
          # /usr/bin, /sbin, etc.
          # Note: we intentionally do NOT add WindowsPowerShell here because Chef 19
          # (Habitat-based) ships its own bundled PowerShell and adding the system
          # PowerShell path could cause version conflicts.
          system_root = ENV.fetch("SystemRoot", 'C:\Windows')
          [
            "#{system_root}\\System32",
            system_root,
            "#{system_root}\\System32\\Wbem",
          ]
        else
          %w{/usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin}
        end
      end

      def __ruby_bindir
        RbConfig::CONFIG["bindir"]
      end

      def __gem_bindir
        Gem.bindir
      end

      extend self
    end
  end
end
