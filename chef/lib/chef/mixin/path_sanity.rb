#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

      def enforce_path_sanity(env=ENV)
        if Chef::Config[:enforce_path_sanity]
          path_separator = Chef::Platform.windows? ? ';' : ':'
          existing_paths = env["PATH"].split(path_separator)
          # ensure the Ruby and Gem bindirs are included
          # mainly for 'full-stack' Chef installs
          paths_to_add = []
          paths_to_add << ruby_bindir unless sane_paths.include?(ruby_bindir)
          paths_to_add << gem_bindir unless sane_paths.include?(gem_bindir)
          paths_to_add << sane_paths if sane_paths
          paths_to_add.flatten!.compact!
          paths_to_add.each do |sane_path|
            unless existing_paths.include?(sane_path)
              env_path = env["PATH"].dup
              env_path << path_separator unless env["PATH"].empty?
              env_path << sane_path
              env["PATH"] = env_path
            end
          end
        end
      end

      private

      def sane_paths
        @sane_paths ||= begin
          if Chef::Platform.windows?
            %w[]
          else
            %w[/usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin]
          end
        end
      end

      def ruby_bindir
        RbConfig::CONFIG['bindir']
      end

      def gem_bindir
        Gem.bindir
      end

    end
  end
end
