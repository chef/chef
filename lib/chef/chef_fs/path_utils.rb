#
# Author:: John Keiser (<jkeiser@chef.io>)
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

require_relative "../chef_fs"
require "pathname" unless defined?(Pathname)

class Chef
  module ChefFS
    class PathUtils

      # A Chef-FS path is a path in a chef-repository that can be used to address
      # both files on a local file-system as well as objects on a chef server.
      # These paths are stricter than file-system paths allowed on various OSes.
      # Absolute Chef-FS paths begin with "/" (on windows, "\" is acceptable as well).
      # "/" is used as the path element separator (on windows, "\" is acceptable as well).
      # No directory/path element may contain a literal "\" character.  Any such characters
      # encountered are either dealt with as separators (on windows) or as escape
      # characters (on POSIX systems).  Relative Chef-FS paths may use ".." or "." but
      # may never use these to back-out of the root of a Chef-FS path.  Any such extraneous
      # ".."s are ignored.
      # Chef-FS paths are case sensitive (since the paths on the server are).
      # On OSes with case insensitive paths, you may be unable to locally deal with two
      # objects whose server paths only differ by case.  OTOH, the case of path segments
      # that are outside the Chef-FS root (such as when looking at a file-system absolute
      # path to discover the Chef-FS root path) are handled in accordance to the rules
      # of the local file-system and OS.

      REGEXP_PATH_SEPARATOR = ChefUtils.windows? ? "[\\/\\\\]" : "/"

      def self.join(*parts)
        return "" if parts.length == 0

        # Determine if it started with a slash
        absolute = parts[0].length == 0 || parts[0].length > 0 && parts[0] =~ /^#{REGEXP_PATH_SEPARATOR}/
        # Remove leading and trailing slashes from each part so that the join will work (and the slash at the end will go away)
        parts = parts.map { |part| part.gsub(/^#{REGEXP_PATH_SEPARATOR}+|#{REGEXP_PATH_SEPARATOR}+$/, "") }
        # Don't join empty bits
        result = parts.select { |part| part != "" }.join("/")
        # Put the / back on
        absolute ? "/#{result}" : result
      end

      def self.split(path)
        path.split(Regexp.new(REGEXP_PATH_SEPARATOR))
      end

      # Given a server path, determines if it is absolute.
      def self.is_absolute?(path)
        !!(path =~ /^#{REGEXP_PATH_SEPARATOR}/)
      end

      # Given a path which may only be partly real (i.e. /x/y/z when only /x exists,
      # or /x/y/*/blah when /x/y/z/blah exists), call File.realpath on the biggest
      # part that actually exists.  The paths operated on here are not Chef-FS paths.
      # These are OS paths that may contain symlinks but may not also fully exist.
      #
      # If /x is a symlink to /foo_bar, and has no subdirectories, then:
      # PathUtils.realest_path('/x/y/z') == '/foo_bar/y/z'
      # PathUtils.realest_path('/x/*/z') == '/foo_bar/*/z'
      # PathUtils.realest_path('/*/y/z') == '/*/y/z'
      #
      # TODO: Move this to wherever util/path_helper is these days.
      def self.realest_path(path, cwd = Dir.pwd)
        path = File.expand_path(path, cwd)
        parent_path = File.dirname(path)
        suffix = []

        # File.dirname happens to return the path as its own dirname if you're
        # at the root (such as at \\foo\bar, C:\ or /)
        until parent_path == path
          # This can occur if a path such as "C:" is given.  Ruby gives the parent as "C:."
          # for reasons only it knows.
          raise ArgumentError "Invalid path segment #{path}" if parent_path.length > path.length

          begin
            path = File.realpath(path)
            break
          rescue Errno::ENOENT, Errno::EINVAL
            suffix << File.basename(path)
            path = parent_path
            parent_path = File.dirname(path)
          end
        end
        File.join(path, *suffix.reverse)
      end

      # Compares two path fragments according to the case-sensitivity of the host platform.
      def self.os_path_eq?(left, right)
        ChefUtils.windows? ? left.casecmp(right) == 0 : left == right
      end

      # Given two general OS-dependent file paths, determines the relative path of the
      # child with respect to the ancestor.  Both child and ancestor must exist and be
      # fully resolved - this is strictly a lexical comparison.  No trailing slashes
      # and other shenanigans are allowed.
      #
      # TODO: Move this to util/path_helper.
      def self.descendant_path(path, ancestor)
        candidate_fragment = path[0, ancestor.length]
        return nil unless PathUtils.os_path_eq?(candidate_fragment, ancestor)

        if ancestor.length == path.length
          ""
        elsif /#{PathUtils::REGEXP_PATH_SEPARATOR}/.match?(path[ancestor.length, 1])
          path[ancestor.length + 1..-1]
        else
          nil
        end
      end

    end
  end
end
