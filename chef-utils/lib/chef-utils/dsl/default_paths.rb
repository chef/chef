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
        # ensure the Ruby and Gem bindirs are included for omnibus chef installs
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
        ChefUtils.windows? ? %w{} : %w{/usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin}
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
