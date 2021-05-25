#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) Chef Software Inc.
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

require "chef-utils" unless defined?(ChefUtils::CANARY)
require_relative "windows"
require_relative "logger"
require_relative "exceptions"

module ChefConfig
  class PathHelper
    # Maximum characters in a standard Windows path (260 including drive letter and NUL)
    WIN_MAX_PATH = 259

    def self.dirname(path, windows: ChefUtils.windows?)
      if windows
        # Find the first slash, not counting trailing slashes
        end_slash = path.size
        loop do
          slash = path.rindex(/[#{Regexp.escape(File::SEPARATOR)}#{Regexp.escape(path_separator(windows: windows))}]/, end_slash - 1)
          if !slash
            return end_slash == path.size ? "." : path_separator(windows: windows)
          elsif slash == end_slash - 1
            end_slash = slash
          else
            return path[0..slash - 1]
          end
        end
      else
        ::File.dirname(path)
      end
    end

    BACKSLASH = "\\".freeze

    def self.path_separator(windows: ChefUtils.windows?)
      if windows
        BACKSLASH
      else
        File::SEPARATOR
      end
    end

    def self.join(*args, windows: ChefUtils.windows?)
      path_separator_regex = Regexp.escape(windows ? "#{File::SEPARATOR}#{BACKSLASH}" : File::SEPARATOR)
      trailing_slashes_regex = /[#{path_separator_regex}]+$/.freeze
      leading_slashes_regex = /^[#{path_separator_regex}]+/.freeze

      args.flatten.inject do |joined_path, component|
        joined_path = joined_path.sub(trailing_slashes_regex, "")
        component = component.sub(leading_slashes_regex, "")
        joined_path + "#{path_separator(windows: windows)}#{component}"
      end
    end

    def self.validate_path(path, windows: ChefUtils.windows?)
      if windows
        unless printable?(path)
          msg = "Path '#{path}' contains non-printable characters. Check that backslashes are escaped with another backslash (e.g. C:\\\\Windows) in double-quoted strings."
          ChefConfig.logger.error(msg)
          raise ChefConfig::InvalidPath, msg
        end

        if windows_max_length_exceeded?(path)
          ChefConfig.logger.trace("Path '#{path}' is longer than #{WIN_MAX_PATH}, prefixing with'\\\\?\\'")
          path.insert(0, "\\\\?\\")
        end
      end

      path
    end

    def self.windows_max_length_exceeded?(path)
      # Check to see if paths without the \\?\ prefix are over the maximum allowed length for the Windows API
      # http://msdn.microsoft.com/en-us/library/windows/desktop/aa365247%28v=vs.85%29.aspx
      unless /^\\\\?\\/.match?(path)
        if path.length > WIN_MAX_PATH
          return true
        end
      end

      false
    end

    def self.printable?(string)
      # returns true if string is free of non-printable characters (escape sequences)
      # this returns false for whitespace escape sequences as well, e.g. \n\t
      if /[^[:print:]]/.match?(string)
        false
      else
        true
      end
    end

    # Produces a comparable path.
    def self.canonical_path(path, add_prefix = true, windows: ChefUtils.windows?)
      # First remove extra separators and resolve any relative paths
      abs_path = File.absolute_path(path)

      if windows
        # Add the \\?\ API prefix on Windows unless add_prefix is false
        # Downcase on Windows where paths are still case-insensitive
        abs_path.gsub!(::File::SEPARATOR, path_separator(windows: windows))
        if add_prefix && abs_path !~ /^\\\\?\\/
          abs_path.insert(0, "\\\\?\\")
        end

        abs_path.downcase!
      end

      abs_path
    end

    # The built in ruby Pathname#cleanpath method does not clean up forward slashes and
    # backslashes.  This is a wrapper around that which does.  In general this is NOT
    # recommended for internal use within ruby/chef since ruby does not care about forward slashes
    # vs. backslashes, even on Windows.  Where this generally matters is when being rendered
    # to the user, or being rendered into things like the windows PATH or to commands that
    # are being executed.  In some cases it may be easier on windows to render paths to
    # unix-style for being eventually eval'd by ruby in the future (templates being rendered
    # with code to be consumed by ruby) where forcing unix-style forward slashes avoids the
    # issue of needing to escape the backslashes in rendered strings.  This has a boolean
    # operator to force windows-style or non-windows style operation, where the default is
    # determined by the underlying node['platform'] value.
    #
    # In general if you don't know if you need this routine, do not use it, best practice
    # within chef/ruby itself is not to care.  Only use it to force windows or unix style
    # when it really matters.
    #
    # @param path [String] the path to clean
    # @param windows [Boolean] optional flag to force to windows or unix-style
    # @return [String] cleaned path
    #
    def self.cleanpath(path, windows: ChefUtils.windows?)
      path = Pathname.new(path).cleanpath.to_s
      if windows
        # ensure all forward slashes are backslashes
        path.gsub(File::SEPARATOR, path_separator(windows: windows))
      else
        # ensure all backslashes are forward slashes
        path.gsub(BACKSLASH, File::SEPARATOR)
      end
    end

    # This is not just escaping for something like use in Regexps, or in globs.  For the former
    # just use Regexp.escape.  For the latter, use escape_glob_dir below.
    #
    # This is escaping where the path to be rendered is being put into a ruby file which will
    # later be read back by ruby (or something similar) so we need quadruple backslashes.
    #
    # In order to print:
    #
    #   file_cache_path "C:\\chef"
    #
    # We need to convert "C:\chef" to "C:\\\\chef" to interpolate into a string which is rendered
    # into the output file with that line in it.
    #
    # @param path [String] the path to escape
    # @return [String] the escaped path
    #
    def self.escapepath(path)
      path.gsub(BACKSLASH, BACKSLASH * 4)
    end

    def self.paths_eql?(path1, path2, windows: ChefUtils.windows?)
      canonical_path(path1, windows: windows) == canonical_path(path2, windows: windows)
    end

    # @deprecated this method is deprecated. Please use escape_glob_dirs
    # Paths which may contain glob-reserved characters need
    # to be escaped before globbing can be done.
    # http://stackoverflow.com/questions/14127343
    def self.escape_glob(*parts, windows: ChefUtils.windows?)
      path = cleanpath(join(*parts, windows: windows), windows: windows)
      path.gsub(/[\\\{\}\[\]\*\?]/) { |x| "\\" + x }
    end

    # This function does not switch to backslashes for windows
    # This is because only forwardslashes should be used with dir (even for windows)
    def self.escape_glob_dir(*parts)
      path = Pathname.new(join(*parts)).cleanpath.to_s
      path.gsub(/[\\\{\}\[\]\*\?]/) { |x| "\\" + x }
    end

    def self.relative_path_from(from, to, windows: ChefUtils.windows?)
      Pathname.new(cleanpath(to, windows: windows)).relative_path_from(Pathname.new(cleanpath(from, windows: windows)))
    end

    # Set the project-specific home directory environment variable.
    #
    # This can be used to allow per-tool home directory aliases like $KNIFE_HOME.
    #
    # @param [env_var] Key for an environment variable to use.
    # @return [nil]
    def self.per_tool_home_environment=(env_var)
      @@per_tool_home_environment = env_var
      # Reset this in case .home was already called.
      @@home_dir = nil
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
    # @see all_homes
    # @param args [Array<String>] Path components to look for under the home directory.
    # @return [String]
    def self.home(*args)
      @@home_dir ||= all_homes { |p| break p }
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
    def self.all_homes(*args, windows: ChefUtils.windows?)
      paths = []
      paths << ENV[@@per_tool_home_environment] if defined?(@@per_tool_home_environment) && @@per_tool_home_environment && ENV[@@per_tool_home_environment]
      paths << ENV["CHEF_HOME"] if ENV["CHEF_HOME"]
      if windows
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

        paths << ENV["HOME"]
        paths << ENV["HOMEDRIVE"] + ENV["HOMEPATH"] if ENV["HOMEDRIVE"] && ENV["HOMEPATH"]
        paths << ENV["HOMESHARE"] + ENV["HOMEPATH"] if ENV["HOMESHARE"] && ENV["HOMEPATH"]
        paths << ENV["USERPROFILE"]
      end
      paths << Dir.home if ENV["HOME"]

      # Depending on what environment variables we're using, the slashes can go in any which way.
      # Just change them all to / to keep things consistent.
      # Note: Maybe this is a bad idea on some unixy systems where \ might be a valid character depending on
      # the particular brand of kool-aid you consume.  This code assumes that \ and / are both
      # path separators on any system being used.
      paths = paths.map { |home_path| home_path.gsub(path_separator(windows: windows), ::File::SEPARATOR) if home_path }

      # Filter out duplicate paths and paths that don't exist.
      valid_paths = paths.select { |home_path| home_path && Dir.exist?(home_path.force_encoding("utf-8")) }
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

    # Determine if the given path is protected by macOS System Integrity Protection.
    def self.is_sip_path?(path, node)
      if ChefUtils.macos?
        # @todo: parse rootless.conf for this?
        sip_paths = [
          "/System", "/bin", "/sbin", "/usr"
        ]
        sip_paths.each do |sip_path|
          ChefConfig.logger.info("#{sip_path} is a SIP path, checking if it is in the exceptions list.")
          return true if path.start_with?(sip_path)
        end
        false
      else
        false
      end
    end

    # Determine if the given path is on the exception list for macOS System Integrity Protection.
    def self.writable_sip_path?(path)
      # todo: parse rootless.conf for this?
      sip_exceptions = [
        "/System/Library/Caches", "/System/Library/Extensions",
        "/System/Library/Speech", "/System/Library/User Template",
        "/usr/libexec/cups", "/usr/local", "/usr/share/man"
      ]
      sip_exceptions.each do |exception_path|
        return true if path.start_with?(exception_path)
      end
      ChefConfig.logger.error("Cannot write to a SIP path #{path} on macOS!")
      false
    end

    # Splits a string into an array of tokens as commands and arguments
    #
    # str = 'command with "some arguments"'
    # split_args(str) => ["command", "with", "\"some arguments\""]
    #
    def self.split_args(line)
      cmd_args = []
      field = ""
      line.scan(/\s*(?>([^\s\\"]+|"([^"]*)"|'([^']*)')|(\S))(\s|\z)?/m) do |word, within_dq, within_sq, esc, sep|

        # Append the string with Word & Escape Character
        field << (word || esc.gsub(/\\(.)/, '\\1'))

        # Re-build the field when any whitespace character or
        # End of string is encountered
        if sep
          cmd_args << field
          field = ""
        end
      end
      cmd_args
    end
  end
end
