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

require 'chef/platform'
require 'chef/exceptions'

class Chef
  class Util
    class PathHelper
      # Maximum characters in a standard Windows path (260 including drive letter and NUL)
      WIN_MAX_PATH = 259

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
        # Rather than find an equivalent for File.absolute_path on 1.8.7, just bail out
        raise NotImplementedError, "This feature is not supported on Ruby versions < 1.9" if RUBY_VERSION.to_f < 1.9

        # First remove extra separators and resolve any relative paths
        abs_path = File.absolute_path(path)

        if Chef::Platform.windows?
          # Add the \\?\ API prefix on Windows unless add_prefix is false
          # Downcase on Windows where paths are still case-insensitive
          abs_path.gsub!(::File::SEPARATOR, ::File::ALT_SEPARATOR)
          if add_prefix && abs_path !~ /^\\\\?\\/
            abs_path.insert(0, "\\\\?\\")
          end

          abs_path.downcase!
        end

        abs_path
      end

      def self.paths_eql?(path1, path2)
        canonical_path(path1) == canonical_path(path2)
      end
    end
  end
end
