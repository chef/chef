#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2013-2018, Chef Software Inc.
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
  class Provider
    class File < Chef::Provider
      class FileEditor
        # Array<String> lines
        attr_accessor :file_contents
        attr_accessor :path

        def initialize(path)
          @path = path
          @file_contents = ::File.readlines(path)
        end

        #
        # DSL methods
        #

        #
        # CFEngine v2 notes:
        #
        # - AppendIfNoLineMatching
        # - AppendIfNoSuchLine
        # - AppendIfNoSuchLinesFromFile
        # - CommentLinesContaining
        # - CommentLinesMatching
        # - CommentLinesStarting
        # - DeleteLinesAfterThisMatching
        # - DeleteLinesContaining / DeleteLinesNotContaining
        # - DeleteLinesMatching / DeleteLinesNotMatching
        # - DeleteLinesStarting / DeteleLinesNotStarting
        # - DeleteLinesNotContainingFileItems
        # - DeleteLinesNotMatchingFileItems
        # - DeleteLinesNotStartingFileItems
        # - FixEndOfLine
        # - HashCommentLinesContaining
        # - HashCommentLinesMatching
        # - HashCommentLinesStarting
        # - InsertFile (change to InsertFileBeforeMatch/AfterMatch w/N lines)
        # - InsertLine (change to InsertLineBeforeMatch/AfterMatch w/N lines)
        # - PercentCommentLinesContaining
        # - PercentCommentLinesMatching
        # - PercentCommentLinesStarting
        # - PrependIfNoLineMatching
        # - PrependIfNoSuchLine
        # - ReplaceAll/With
        # - ReplaceFirst/With
        # - SetCommentStart/End
        # - SlashCommentLinesContaining
        # - SlashCommentLinesMatching
        # - SlashCommentLinesStarting
        # - UnCommentLinesContaining
        # - UnCommentLinesMatching

        #
        # ADD:
        #
        # - remove_if_empty (true/false) : remove the file if the contents are all deleted (default false)
        #
        # WARNING:  Chef Software Inc owns all methods in this namespace, you MUST NOT monkeypatch or inject
        # methods directly into this class.  You may create your own module of helper functions and `extend`
        # those directly into the blocks where you use the helpers.
        #
        # in e.g. libraries/my_helper.rb:
        #
        # module AcmeMyHelpers
        #   def acme_do_a_thing ... end
        # end
        #
        # in e.g. recipes/default.rb:
        #
        # file "/tmp/foo.xyz" do
        #   edit do
        #     extend AcmeMyHelpers
        #     acme_do_a_thing
        #     [...]
        #   end
        # end
        #
        # It is still recommended that you namespace your custom helpers so as not to have collisions with future
        # methods added to this class.
        #
        # FIXME: it feels like we should add DSL sugar for this?
        #

        def empty!
          @file_contents = []
        end

        # set the eol string for the file
        def eol(val)
          # FIXME: yeah, windows stuff is all totes broken right now
        end

        # repetetive "append_if_no_such_line"
        #
        # Examples:
        #
        # append_lines({
        #   /NETWORLKING.*=/ => "NETWORKING=yes"
        #   /HOSTNAME.*=/ => "HOSTNAME=foo.acme.com"
        # }, replace: true, unique: true)
        #
        # @param lines [ String, Array<String>, Hash{Regexp,String => String} ] lines to append
        # @param replace [ true, false ] If set to true, all existing lines will be replaced
        # @param unique [ true, false ] If unique is false, all lines are replaced.  If unique is true only the
        #        last match is replaced and the other matches are deleted from the file.
        # @return [ Array<String> ] the file_contets array, or nil if there was no modifications
        #
        def append_lines(lines, replace: false, unique: false)
          chkarg 1, lines, [ Array, String, Hash ]
          chkarg :replace, replace, [ true, false ]
          chkarg :unique, unique, [ true, false ]

          unless lines.is_a?(Hash)
            lines = lines.split("\n") unless lines.is_a?(Array)
            lines.map(&:chomp!)
            lines = lines.each_with_object({}) do |line, hash|
              regex = /^#{Regexp.escape(line)}$/
              hash[regex] = line
            end
          end
          modified = false
          lines.each do |regex, line|
            append_line_unless_match(regex, line, replace: replace, unique: unique) && modified = true
          end
          modified ? file_contents : nil
        end

        # lower level one-line-at-a-time
        # @return [ Array<String> ] the file_contets array, or nil if there was no modifications
        #
        def append_line_unless_match(pattern, line, replace: false, unique: false)
          chkarg 1, pattern, [ String, Regexp ]
          chkarg 2, line, String
          chkarg :replace, replace, [ true, false ]
          chkarg :unique, unique, [ true, false ]

          modified = false
          regex = pattern.is_a?(String) ? /#{Regexp.escape(pattern)}/ : pattern
          if file_contents.grep(regex).empty?
            unless file_contents.empty?
              file_contents[-1].chomp!
              file_contents[-1] << "\n"
            end
            file_contents.push(line + "\n")
            modified = true
          else
            if replace
              replace_lines(regex, line, unique: unique ? :last : false) && modified = true
            end
          end
          modified ? file_contents : nil
        end

        # repetitive "prepend_if_no_such_line"
        # @return [ Array<String> ] the file_contets array, or nil if there was no modifications
        #
        def prepend_lines(lines, replace: false, unique: false)
          chkarg 1, lines, [ Array, String, Hash ]
          chkarg :replace, replace, [ true, false ]
          chkarg :unique, unique, [ true, false ]

          unless lines.is_a?(Hash)
            lines = lines.split("\n") unless lines.is_a?(Array)
            lines.map(&:chomp!)
            lines = lines.reverse.each_with_object({}) do |line, hash|
              regex = /^#{Regexp.escape(line)}$/
              hash[regex] = line
            end
          end
          modified = false
          lines.each do |regex, line|
            prepend_line_unless_match(regex, line, replace: replace, unique: unique) && modified = true
          end
        end

        # @return [ Array<String> ] the file_contets array, or nil if there was no modifications
        #
        def prepend_line_unless_match(pattern, line, replace: false, unique: false)
          chkarg 1, pattern, [ String, Regexp ]
          chkarg 2, line, String
          chkarg :replace, replace, [ true, false ]
          chkarg :unique, unique, [ true, false ]

          modified = false
          regex = pattern.is_a?(String) ? /#{Regexp.escape(pattern)}/ : pattern
          if file_contents.grep(regex).empty?
            file_contents.unshift(line + "\n")
            modified = true
          else
            if replace
              replace_lines(regex, line, unique: unique ? :first : false) && modified = true
            end
          end
          modified ? file_contents : nil
        end

        # mass delete
        def delete_lines_matching(pattern)
          regex = pattern.is_a?(String) ? /#{Regexp.escape(pattern)}/ : pattern
          file_contents.reject! { |l| l =~ regex }
        end

        # delimited delete
        def delete_between(start:, finish:, inclusive: false)
          start = start.is_a?(String) ? /#{Regexp.escape(start)}/ : start
          finish = finish.is_a?(String) ? /#{Regexp.escape(finish)}/ : finish
          # find the start
          i_start = file_contents.find_index { |l| l =~ start }
          return unless i_start
          # find the finish
          i_finish = nil
          i_start.upto(file_contents.size - 1) do |i|
            if i >= i_start && file_contents[i] =~ finish
              i_finish = i
              break
            end
          end
          return unless i_finish
          file_contents.slice!(i_start, i_finish)
        end

        def replace_between(lines, start:, finish:)
        end

        # Search the entire file for matches on each line.  When the line matches, replace the line with the given string.  Can also be
        # used to assert that only one occurance of the match is kept in the file.
        #
        # @param match [ String, Regexp ] The regular expression or substring to match
        # @param line [ String ] The line to replace matching lines with
        # @param unique [ false, :first, :last ] If unique is false, all lines are replaced.  If unique is set to :first or :last only the
        #        first or last match is replaced and the other matches are deleted from the file.
        # @return [ Array<String> ] the file_contets array, or nil if there was no modifications
        #
        def replace_lines(match, line, unique: false)
          chkarg 1, match, [ String, Regexp ]
          chkarg 2, line, String
          chkarg :unique, unique, [ false, :first, :last ]

          regex = match.is_a?(String) ? /#{Regexp.escape(match)}/ : match
          modified = false
          file_contents.reverse! if unique == :last # FIXME: this is probably expensive
          found = false
          file_contents.map! do |l|
            ret = if l != line + "\n" && regex.match?(l)
                    modified = true
                    if !(unique && found)
                      line + "\n"
                    else
                      nil
                    end
                  else
                    l
                  end
            found = true if regex.match?(l)
            ret
          end.compact!
          file_contents.reverse! if unique == :last
          modified ? file_contents : nil
        end

        # mass search-and-replace on substrings
        def substitute_lines(match, replace, global: false)
          chkarg 1, match, [ String, Regexp ]
          chkarg 2, replace, String
          chkarg :global, global, [ false, true ]

          regex = match.is_a?(String) ? /#{Regexp.escape(match)}/ : match
          modified = false
          if global
            file_contents.each do |l|
              old = l
              l.gsub!(regex, replace)
              modified = true if l != old
            end
          else
            file_contents.each do |l|
              old = l
              l.sub!(regex, replace)
              modified = true if l != old
            end
          end
          modified ? file_contents : nil
        end

        # delimited search-and-replace
        def substitute_between(start:, finish:, match:, replace:, global: false, inclusive: false)
          start = start.is_a?(String) ? /#{Regexp.escape(start)}/ : start
          finish = finish.is_a?(String) ? /#{Regexp.escape(finish)}/ : finish
          match = match.is_a?(String) ? /#{Regexp.escape(match)}/ : match
          # find the start
          i_start = file_contents.find_index { |l| l =~ start }
          return unless i_start
          # find the finish
          i_finish = nil
          i_start.upto(file_contents.size - 1) do |i|
            if i >= i_start && file_contents[i] =~ finish
              i_finish = i
              break
            end
          end
          return unless i_finish
          # do the substitution on the block
          if global
            i_start.upto(i_finish) { |i| file_contents[i].gsub!(match, replace) }
          else
            i_start.upto(i_finish) { |i| file_contents[i].sub!(match, replace) }
          end
        end

        # NOTE: This is intented to be used only on a tempfile so we open, truncate and append
        # because the file provider already has the machinery to atomically move a tempfile into place.
        # If we crash in the middle it doesn't matter if we leave a corrupted tempfile to be
        # garbage collected as ruby exits.  If you feel you need to add atomicity here you probably
        # want to use a file provider directly or fix your own code to provide a tempfile to this
        # one and handle the atomicity yourself.
        #
        # This is not intended as a DSL method for end users, it has to be public visibility, but you
        # should not use it.
        #
        # @api private
        def finish!
          ::File.open(path, "w") do |f|
            f.write file_contents.join
          end
        end

        private

        # FIXME: make this a mixin in chef-helper
        # @api private
        def chkarg(what, arg, matches)
          matches = Array( matches )
          matches.each do |match|
            return true if match === arg
          end
          method = caller_locations(1, 1)[0].label
          whatstr = if what.is_a?(Integer)
                      "#{ordinalize(what)} argument"
                    else
                      "named '#{what}' argument"
                    end
          raise ArgumentError, "#{whatstr} to #{method} must be one of: #{matches.map { |v| v.inspect }.join(", ")}, you gave: #{arg.inspect}"
        end

        # FIXME: make this a mixin in chef-helper (and yeah we could humanize it and spell it out, but ain't got time for that)
        # @api private
        def ordinalize(int)
          s = int.to_s
          case
          when s.end_with?("1")
            "#{int}st"
          when s.end_with?("2")
            "#{int}nd"
          when s.end_with?("3")
            "#{int}rd"
          else
            "#{int}th"
          end
        end
      end
    end
  end
end
