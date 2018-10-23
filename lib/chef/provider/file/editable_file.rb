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
      class EditableFile
        # String path to the file
        attr_accessor :path

        # Array<String> lines in the file
        attr_accessor :file_contents

        # Hash<String> dictionary of location objects by name
        def locations
          @locations ||= {}
        end

        # Hash<String> dictionary of region objects by name
        def regions
          @regions ||= {}
        end

        class Location
          attr_accessor :name
          attr_accessor :editable_file

          def initialize(editable_file, name)
            @editable_file = editable_file
            @name = name
            @before = false
            @first = false
            @match = /.*/
          end

          def before(arg = nil)
            @before = !!arg unless arg.nil?
            @before
          end

          def after(arg = nil)
            @before = !arg unless arg.nil?
            !@before
          end

          def first(arg = nil)
            @first = !!arg unless arg.nil?
            @first
          end

          def last(arg = nil)
            @first = !arg unless arg.nil?
            !@first
          end

          def match(pattern = nil)
            if pattern
              @match = pattern.is_a?(String) ? /#{Regexp.escape(pattern)}/ : pattern
            end
            @match
          end

          def index
            iterator = ( first ) ? :each : :reverse_each
            editable_file.file_contents.send(iterator).with_index do |line, i|
              i = ( first ) ? i : editable_file.file_contents.length - i - 1
              if match.match?(line)
                return before ? i : i + 1
              end
            end
            raise "match not found" # FIXME: better error
          end
        end

        class Region
          attr_accessor :name
          def initialize(name)
            @name = name
          end
        end

        def empty!
          @file_contents = []
        end

        def initialize(file_contents, path)
          @file_contents = file_contents
          @path = path
        end

        def self.from_file(path)
          new(::File.readlines(path), path)
        end

        def self.from_string(string, path_out)
          new(string.lines, path_out)
        end

        def self.from_array(array, path_out)
          new(array, path_out)
        end

        # @param lines [ String, IO, Array<String> ] source of the lines to insert
        # @param ignore_leading [ Boolean ] ignore leading whitespace in the idempotency check
        # @param ignore_trailing [ Boolean ] ignore traliing whitespece in the idempotency check
        # @param ignore_embedded [ Boolean ] ignore embedded whitespace in the idempotency check
        # @param idempotency [ Boolean ] set to false to ignore the idempotency check entirely
        # FIXME: @param preserve_block [ Boolean ] if `what` is multi-line treat it as a block of lines, not individual lines
        # FIXME: insert_select support for files?
        def insert(lines, location:, ignore_leading: false, ignore_trailing: false, ignore_embedded: false, idempotency: true) # , preserve_block: false)
          lines = lines.read if lines.is_a?(IO)
          lines = lines.lines if lines.is_a?(String)
          lines = Array( lines )
          lines.each do |line|
            if idempotency
              regexp = generate_regexp(line, ignore_leading: ignore_leading, ignore_trailing: ignore_trailing, ignore_embedded: ignore_embedded)
              next if file_contents.any? { |l| l.match?(regexp) }
            end
            idx = locations[location].index
            file_contents.insert(idx, line + "\n")
          end
        end

        # FIXME: delete_select support for files?
        def delete(lines, ignore_leading: false, ignore_trailing: false, ignore_embedded: false, not_matching: false)
          lines = lines.read if lines.is_a?(IO)
          lines = lines.lines if lines.is_a?(String)
          lines = Array( lines )
          lines.each do |line|
            regexp =
              if line.is_a?(Regexp)
                line
              else
                generate_regexp(line, ignore_leading: ignore_leading, ignore_trailing: ignore_trailing, ignore_embedded: ignore_embedded)
              end
            file_contents.reject! { |line| not_matching ? !regexp.match?(line) : regexp.match?(line) }
          end
        end

        def replace(regexp, with)
          file_contents.map! { |line| line.gsub!(regexp, with) }
        end

        # @return <Location> the new location object
        def location(name, &block)
          l = Location.new(self, name)
          l.instance_exec(&block) if block_given?
          locations[name] = l
        end

        # @return <Region> the new region object
        def region(name, &block)
          r = Region.new(name)
          r.instance_exec(&block) if block_given?
          regions[name] = r
        end

        def finish!
          ::File.open(path, "w") do |f|
            f.write file_contents.join
          end
        end

        private

        def generate_regexp(string, ignore_leading: false, ignore_trailing: false, ignore_embedded: false)
          escaped =
            if ignore_embedded
              string.split(/\s+/).map { |s| Regexp.escape(s) }.join('\s+')
            else
              Regexp.escape(string)
            end
          string = string.gsub(/\s+/, '\s+')
          regexp_str = "^"
          regexp_str << '\s*' if ignore_leading
          regexp_str << escaped
          regexp_str << '\s*' if ignore_trailing
          regexp_str << "$"
          Regexp.new(regexp_str)
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

      end
    end
  end
end
