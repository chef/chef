#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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
  class Util
    class PathHelper
      # Maximum characters in a standard Windows path (260 including drive letter and NUL)
      WIN_MAX_PATH = 259

      def self.dirname(path)
        if Chef::Platform.windows?
          # Find the first slash, not counting trailing slashes
          end_slash = path.size
          loop do
            slash = path.rindex(/[#{Regexp.escape(File::SEPARATOR)}#{Regexp.escape(path_separator)}]/, end_slash - 1)
            if !slash
              return end_slash == path.size ? '.' : path_separator
            elsif slash == end_slash - 1
              end_slash = slash
            else
              return path[0..slash-1]
            end
          end
        else
          ::File.dirname(path)
        end
      end

      BACKSLASH = '\\'.freeze

      def self.path_separator
        if Chef::Platform.windows?
          File::ALT_SEPARATOR || BACKSLASH
        else
          File::SEPARATOR
        end
      end

      def self.join(*args)
        args.flatten.inject do |joined_path, component|
          # Joined path ends with /
          joined_path = joined_path.sub(/[#{Regexp.escape(File::SEPARATOR)}#{Regexp.escape(path_separator)}]+$/, '')
          component = component.sub(/^[#{Regexp.escape(File::SEPARATOR)}#{Regexp.escape(path_separator)}]+/, '')
          joined_path += "#{path_separator}#{component}"
        end
      end

      def self.validate_path(path)
        if Chef::Platform.windows?
          unless printable?(path)
            msg = "Path '#{path}' contains non-printable characters. Check that backslashes are escaped with another backslash (e.g. C:\\\\Windows) in double-quoted strings."
            Chef::Log.error(msg)
            raise Chef::Exceptions::ValidationFailed, msg
          end

          if windows_max_length_exceeded?(path)
            Chef::Log.debug("Path '#{path}' is longer than #{WIN_MAX_PATH}, prefixing with'\\\\?\\'")
            path.insert(0, "\\\\?\\")
          end
        end

        path
      end

      def self.windows_max_length_exceeded?(path)
        # Check to see if paths without the \\?\ prefix are over the maximum allowed length for the Windows API
        # http://msdn.microsoft.com/en-us/library/windows/desktop/aa365247%28v=vs.85%29.aspx
        unless path =~ /^\\\\?\\/
          if path.length > WIN_MAX_PATH
            return true
          end
        end

        false
      end

      def self.printable?(string)
        # returns true if string is free of non-printable characters (escape sequences)
        # this returns false for whitespace escape sequences as well, e.g. \n\t
        if string =~ /[^[:print:]]/
          false
        else
          true
        end
      end

      # Produces a comparable path.
      def self.canonical_path(path, add_prefix=true)
        # First remove extra separators and resolve any relative paths
        abs_path = File.absolute_path(path)

        if Chef::Platform.windows?
          # Add the \\?\ API prefix on Windows unless add_prefix is false
          # Downcase on Windows where paths are still case-insensitive
          abs_path.gsub!(::File::SEPARATOR, path_separator)
          if add_prefix && abs_path !~ /^\\\\?\\/
            abs_path.insert(0, "\\\\?\\")
          end

          abs_path.downcase!
        end

        abs_path
      end

      def self.cleanpath(path)
        path = Pathname.new(path).cleanpath.to_s
        # ensure all forward slashes are backslashes
        if Chef::Platform.windows?
          path = path.gsub(File::SEPARATOR, path_separator)
        end
        path
      end

      def self.paths_eql?(path1, path2)
        canonical_path(path1) == canonical_path(path2)
      end

      # Paths which may contain glob-reserved characters need
      # to be escaped before globbing can be done.
      # http://stackoverflow.com/questions/14127343
      def self.escape_glob(*parts)
        path = cleanpath(join(*parts))
        path.gsub(/[\\\{\}\[\]\*\?]/) { |x| "\\"+x }
      end

      def self.relative_path_from(from, to)
        pathname = Pathname.new(Chef::Util::PathHelper.cleanpath(to)).relative_path_from(Pathname.new(Chef::Util::PathHelper.cleanpath(from)))
      end

      # Retrieves the "home directory" of the current user while trying to ascertain the existence
      # of said directory.  The path returned uses / for all separators (the ruby standard format).
      # If the home directory doesn't exist or an error is otherwise encountered, nil is returned.
      # 
      # If a set of path elements is provided, they are appended as-is to the home path if the
      # homepath exists. 
      # 
      # If an optional block is provided, the joined path is passed to that block if the home path is
      # valid and the result of the block is returned instead.
      #
      # Home-path discovery is performed once.  If a path is discovered, that value is memoized so
      # that subsequent calls to home_dir don't bounce around.
      #
      # See self.all_homes.
      def self.home(*args)
        @@home_dir ||= self.all_homes { |p| break p }
        if @@home_dir
          path = File.join(@@home_dir, *args)
          block_given? ? (yield path) : path
        end
      end

      # See self.home.  This method performs a similar operation except that it yields all the different
      # possible values of 'HOME' that one could have on this platform.  Hence, on windows, if
      # HOMEDRIVE\HOMEPATH and USERPROFILE are different, the provided block will be called twice.
      # This method goes out and checks the existence of each location at the time of the call.
      #
      # The return is a list of all the returned values from each block invocation or a list of paths
      # if no block is provided.
      def self.all_homes(*args)
        paths = []
        if Chef::Platform.windows?
          # By default, Ruby uses the the following environment variables to determine Dir.home:
          # HOME
          # HOMEDRIVE HOMEPATH
          # USERPROFILE
          # Ruby only checks to see if the variable is specified - not if the directory actually exists.
          # On Windows, HOMEDRIVE HOMEPATH can point to a different location (such as an unavailable network mounted drive)
          # while USERPROFILE points to the location where the user application settings and profile are stored.  HOME
          # is not defined as an environment variable (usually).  If the home path actually uses UNC, then the prefix is
          # HOMESHARE instead of HOMEDRIVE.
          #
          # We instead walk down the following and only include paths that actually exist.
          # HOME
          # HOMEDRIVE HOMEPATH
          # HOMESHARE HOMEPATH
          # USERPROFILE

          paths << ENV['HOME']
          paths << ENV['HOMEDRIVE'] + ENV['HOMEPATH'] if ENV['HOMEDRIVE'] && ENV['HOMEPATH']
          paths << ENV['HOMESHARE'] + ENV['HOMEPATH'] if ENV['HOMESHARE'] && ENV['HOMEPATH']
          paths << ENV['USERPROFILE']
        end
        paths << Dir.home if ENV['HOME']

        # Depending on what environment variables we're using, the slashes can go in any which way.
        # Just change them all to / to keep things consistent.
        # Note: Maybe this is a bad idea on some unixy systems where \ might be a valid character depending on
        # the particular brand of kool-aid you consume.  This code assumes that \ and / are both
        # path separators on any system being used.
        paths = paths.map { |home_path| home_path.gsub(path_separator, ::File::SEPARATOR) if home_path }

        # Filter out duplicate paths and paths that don't exist.
        valid_paths = paths.select { |home_path| home_path && Dir.exists?(home_path) }
        valid_paths = valid_paths.uniq

        # Join all optional path elements at the end.
        # If a block is provided, invoke it - otherwise just return what we've got.
        joined_paths = valid_paths.map { |home_path| File.join(home_path, *args) }
        if block_given?
          joined_paths.each { |p| yield p }
        else
          joined_paths
        end
      end
    end
  end
end

# Break a require loop when require chef/util/path_helper
require 'chef/platform'
require 'chef/exceptions'
