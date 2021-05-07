#
# Author:: John Keiser (<jkeiser@chef.io>)
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

require_relative "../chef_fs"
require_relative "path_utils"

class Chef
  module ChefFS
    #
    # Represents a glob pattern.  This class is designed so that it can
    # match arbitrary strings, and tell you about partial matches.
    #
    # Examples:
    # * <tt>a*z</tt>
    #   - Matches <tt>abcz</tt>
    #   - Does not match <tt>ab/cd/ez</tt>
    #   - Does not match <tt>xabcz</tt>
    # * <tt>a**z</tt>
    #   - Matches <tt>abcz</tt>
    #   - Matches <tt>ab/cd/ez</tt>
    #
    # Special characters supported:
    # * <tt>/</tt> (and <tt>\\</tt> on Windows) - directory separators
    # * <tt>\*</tt> - match zero or more characters (but not directory separators)
    # * <tt>\*\*</tt> - match zero or more characters, including directory separators
    # * <tt>?</tt> - match exactly one character (not a directory separator)
    # Only on Unix:
    # * <tt>[abc0-9]</tt> - match one of the included characters
    # * <tt>\\<character></tt> - escape character: match the given character
    #
    class FilePattern
      # Initialize a new FilePattern with the pattern string.
      #
      # Raises +ArgumentError+ if empty file pattern is specified
      def initialize(pattern)
        @pattern = pattern
      end

      # The pattern string.
      attr_reader :pattern

      # Reports whether this pattern could match children of <tt>path</tt>.
      # If the pattern doesn't match the path up to this point or
      # if it matches and doesn't allow further children, this will
      # return <tt>false</tt>.
      #
      # ==== Attributes
      #
      # * +path+ - a path to check
      #
      # ==== Examples
      #
      #   abc/def.could_match_children?('abc') == true
      #   abc.could_match_children?('abc') == false
      #   abc/def.could_match_children?('x') == false
      #   a**z.could_match_children?('ab/cd') == true
      def could_match_children?(path)
        return false if path == "" # Empty string is not a path

        argument_is_absolute = Chef::ChefFS::PathUtils.is_absolute?(path)
        return false if is_absolute != argument_is_absolute

        path = path[1, path.length - 1] if argument_is_absolute

        path_parts = Chef::ChefFS::PathUtils.split(path)
        # If the pattern is shorter than the path (or same size), children will be larger than the pattern, and will not match.
        return false if regexp_parts.length <= path_parts.length && !has_double_star
        # If the path doesn't match up to this point, children won't match either.
        return false if path_parts.zip(regexp_parts).any? { |part, regexp| !regexp.nil? && !regexp.match(part) }

        # Otherwise, it's possible we could match: the path matches to this point, and the pattern is longer than the path.
        # TODO There is one edge case where the double star comes after some characters like abc**def--we could check whether the next
        # bit of path starts with abc in that case.
        true
      end

      # Returns the immediate child of a path that would be matched
      # if this FilePattern was applied.  If more than one child
      # could match, this method returns nil.
      #
      # ==== Attributes
      #
      # * +path+ - The path to look for an exact child name under.
      #
      # ==== Returns
      #
      # The next directory in the pattern under the given path.
      # If the directory part could match more than one child, it
      # returns +nil+.
      #
      # ==== Examples
      #
      #   abc/def.exact_child_name_under('abc') == 'def'
      #   abc/def/ghi.exact_child_name_under('abc') == 'def'
      #   abc/*/ghi.exact_child_name_under('abc') == nil
      #   abc/*/ghi.exact_child_name_under('abc/def') == 'ghi'
      #   abc/**/ghi.exact_child_name_under('abc/def') == nil
      #
      # This method assumes +could_match_children?(path)+ is +true+.
      def exact_child_name_under(path)
        path = path[1, path.length - 1] if Chef::ChefFS::PathUtils.is_absolute?(path)
        dirs_in_path = Chef::ChefFS::PathUtils.split(path).length
        return nil if exact_parts.length <= dirs_in_path

        exact_parts[dirs_in_path]
      end

      # If this pattern represents an exact path, returns the exact path.
      #
      #   abc/def.exact_path == 'abc/def'
      #   abc/*def.exact_path == 'abc/def'
      #   abc/x\\yz.exact_path == 'abc/xyz'
      def exact_path
        return nil if has_double_star || exact_parts.any?(&:nil?)

        result = Chef::ChefFS::PathUtils.join(*exact_parts)
        is_absolute ? Chef::ChefFS::PathUtils.join("", result) : result
      end

      # Returns the normalized version of the pattern, with / as the directory
      # separator, and "." and ".." removed.
      #
      # This does not presently change things like \b to b, but in the future
      # it might.
      def normalized_pattern
        calculate
        @normalized_pattern
      end

      # Tell whether this pattern matches absolute, or relative paths
      def is_absolute
        calculate
        @is_absolute
      end

      # Returns <tt>true+ if this pattern matches the path, <tt>false+ otherwise.
      #
      #   abc/*/def.match?('abc/foo/def') == true
      #   abc/*/def.match?('abc/foo') == false
      def match?(path)
        argument_is_absolute = Chef::ChefFS::PathUtils.is_absolute?(path)
        return false if is_absolute != argument_is_absolute

        path = path[1, path.length - 1] if argument_is_absolute
        !!regexp.match(path)
      end

      # Returns the string pattern
      def to_s
        pattern
      end

      private

      def regexp
        calculate
        @regexp
      end

      def regexp_parts
        calculate
        @regexp_parts
      end

      def exact_parts
        calculate
        @exact_parts
      end

      def has_double_star
        calculate
        @has_double_star
      end

      def calculate
        unless @regexp
          @is_absolute = Chef::ChefFS::PathUtils.is_absolute?(@pattern)

          full_regexp_parts = []
          normalized_parts = []
          @regexp_parts = []
          @exact_parts = []
          @has_double_star = false

          Chef::ChefFS::PathUtils.split(pattern).each do |part|
            regexp, exact, has_double_star = FilePattern.pattern_to_regexp(part)
            if has_double_star
              @has_double_star = true
            end

            # Skip // and /./ (pretend it's not there)
            if ["", "."].include?(exact)
              next
            end

            # Back up when you see .. (unless the prior part has ** in it, in which case .. must be preserved)
            if exact == ".."
              if @is_absolute && normalized_parts.length == 0
                # If we are at the root, just pretend the .. isn't there
                next
              elsif normalized_parts.length > 0
                regexp_prev, exact_prev, has_double_star_prev = FilePattern.pattern_to_regexp(normalized_parts[-1])
                if has_double_star_prev
                  raise ArgumentError, ".. overlapping a ** is unsupported"
                end

                full_regexp_parts.pop
                normalized_parts.pop
                unless @has_double_star
                  @regexp_parts.pop
                  @exact_parts.pop
                end
                next
              end
            end

            # Build up the regexp
            full_regexp_parts << regexp
            normalized_parts << part
            unless @has_double_star
              @regexp_parts << Regexp.new("^#{regexp}$")
              @exact_parts << exact
            end
          end

          @regexp = Regexp.new("^#{full_regexp_parts.join(Chef::ChefFS::PathUtils.regexp_path_separator)}$")
          @normalized_pattern = Chef::ChefFS::PathUtils.join(*normalized_parts)
          @normalized_pattern = Chef::ChefFS::PathUtils.join("", @normalized_pattern) if @is_absolute
        end
      end

      def self.pattern_special_characters
        if ChefUtils.windows?
          @pattern_special_characters ||= /(\*\*|\*|\?|[\*\?\.\|\(\)\[\]\{\}\+\\\\\^\$])/
        else
          # Unix also supports character regexes and backslashes
          @pattern_special_characters ||= /(\\.|\[[^\]]+\]|\*\*|\*|\?|[\*\?\.\|\(\)\[\]\{\}\+\\\\\^\$])/
        end
        @pattern_special_characters
      end

      def self.regexp_escape_characters
        [ "[", "\\", "^", "$", ".", "|", "?", "*", "+", "(", ")", "{", "}" ]
      end

      def self.pattern_to_regexp(pattern)
        regexp = ""
        exact = ""
        has_double_star = false
        pattern.split(pattern_special_characters).each_with_index do |part, index|
          # Odd indexes from the split are symbols.  Even are normal bits.
          if index.even?
            exact << part unless exact.nil?
            regexp << part
          else
            case part
            # **, * and ? happen on both platforms.
            when "**"
              exact = nil
              has_double_star = true
              regexp << ".*"
            when "*"
              exact = nil
              regexp << '[^\/]*'
            when "?"
              exact = nil
              regexp << "."
            else
              if part[0, 1] == "\\" && part.length == 2
                # backslash escapes are only supported on Unix, and are handled here by leaving the escape on (it means the same thing in a regex)
                exact << part[1, 1] unless exact.nil?
                if regexp_escape_characters.include?(part[1, 1])
                  regexp << part
                else
                  regexp << part[1, 1]
                end
              elsif part[0, 1] == "[" && part.length > 1
                # [...] happens only on Unix, and is handled here by *not* backslashing (it means the same thing in and out of regex)
                exact = nil
                regexp << part
              else
                exact += part unless exact.nil?
                regexp << "\\#{part}"
              end
            end
          end
        end
        [regexp, exact, has_double_star]
      end
    end
  end
end
