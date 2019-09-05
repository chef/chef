#
# Copyright:: Copyright 2018-2018, Chef Software Inc.
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

require 'chef-helpers/internal'
require 'chef-helpers/platform_family'

module ChefHelpers
  module PathSanity
    extend self

    def sanitized_path
      env_path = Internal.env_path.nil? ? "" : Internal.env_path.dup
      path_separator = PlatformFamily.windows? ? ";" : ":"
      # ensure the Ruby and Gem bindirs are included
      # mainly for 'full-stack' Chef installs
      new_paths = env_path.split(path_separator)
      [ ruby_bindir, gem_bindir ].compact.each do |path|
        new_paths = [ path ] + new_paths unless new_paths.include?(path)
      end
      sane_paths.each do |path|
        new_paths << path unless new_paths.include?(path)
      end
      new_paths.join(path_separator).scrub
    end

    class << self
      def sane_paths
        PlatformFamily.windows? ? %w{} : %w{/usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin}
      end

      def ruby_bindir
        RbConfig::CONFIG["bindir"]
      end

      def gem_bindir
        Gem.bindir
      end
    end
  end
end
