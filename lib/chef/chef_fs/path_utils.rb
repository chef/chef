#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'chef/chef_fs'
require 'pathname'

class Chef
  module ChefFS
    class PathUtils

      # If you are in 'source', this is what you would have to type to reach 'dest'
      # relative_to('/a/b/c/d/e', '/a/b/x/y') == '../../c/d/e'
      # relative_to('/a/b', '/a/b') == '.'
      def self.relative_to(dest, source)
        # Skip past the common parts
        source_parts = Chef::ChefFS::PathUtils.split(source)
        dest_parts = Chef::ChefFS::PathUtils.split(dest)
        i = 0
        until i >= source_parts.length || i >= dest_parts.length || source_parts[i] != dest_parts[i]
          i+=1
        end
        # dot-dot up from 'source' to the common ancestor, then
        # descend to 'dest' from the common ancestor
        result = Chef::ChefFS::PathUtils.join(*(['..']*(source_parts.length-i) + dest_parts[i,dest.length-i]))
        result == '' ? '.' : result
      end

      def self.join(*parts)
        return "" if parts.length == 0
        # Determine if it started with a slash
        absolute = parts[0].length == 0 || parts[0].length > 0 && parts[0] =~ /^#{regexp_path_separator}/
        # Remove leading and trailing slashes from each part so that the join will work (and the slash at the end will go away)
        parts = parts.map { |part| part.gsub(/^\/|\/$/, "") }
        # Don't join empty bits
        result = parts.select { |part| part != "" }.join("/")
        # Put the / back on
        absolute ? "/#{result}" : result
      end

      def self.split(path)
        path.split(Regexp.new(regexp_path_separator))
      end

      def self.regexp_path_separator
        Chef::ChefFS::windows? ? '[\/\\\\]' : '/'
      end

      # Given a path which may only be partly real (i.e. /x/y/z when only /x exists,
      # or /x/y/*/blah when /x/y/z/blah exists), call File.realpath on the biggest
      # part that actually exists.
      #
      # If /x is a symlink to /blarghle, and has no subdirectories, then:
      # PathUtils.realest_path('/x/y/z') == '/blarghle/y/z'
      # PathUtils.realest_path('/x/*/z') == '/blarghle/*/z'
      # PathUtils.realest_path('/*/y/z') == '/*/y/z'
      def self.realest_path(path)
        path = Pathname.new(path)
        begin
          path.realpath.to_s
        rescue Errno::ENOENT
          dirname = path.dirname
          if dirname
            PathUtils.join(realest_path(dirname), path.basename.to_s)
          else
            path.to_s
          end
        end
      end

      def self.is_absolute?(path)
        path =~ /^#{regexp_path_separator}/
      end
    end
  end
end
