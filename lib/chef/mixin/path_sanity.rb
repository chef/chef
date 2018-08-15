#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright 2011-2017, Chef Software Inc.
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

class Chef
  module Mixin
    module PathSanity

      def enforce_path_sanity(env = ENV)
        if Chef::Config[:enforce_path_sanity]
          env["PATH"] = sanitized_path(env)
        end
      end

      def sanitized_path(env = ENV)
        env_path = env["PATH"].nil? ? "" : env["PATH"].dup
        path_separator = Chef::Platform.windows? ? ";" : ":"
        # ensure the Ruby and Gem bindirs are included
        # mainly for 'full-stack' Chef installs
        new_paths = env_path.split(path_separator)
        [ ruby_bindir, gem_bindir ].compact.each do |path|
          new_paths = [ path ] + new_paths unless new_paths.include?(path)
        end
        sane_paths.each do |path|
          new_paths << path unless new_paths.include?(path)
        end
        new_paths.join(path_separator).encode("utf-8", invalid: :replace, undef: :replace)
      end

      private

      def sane_paths
        @sane_paths ||= begin
          if Chef::Platform.windows?
            %w{}
          else
            %w{/usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin}
          end
        end
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
