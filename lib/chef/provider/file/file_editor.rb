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

        def empty!
          @file_contents = []
        end

        def append_if_no_such_line(line)
          regex = /^#{Regexp.escape(line)}$/
          append_if_no_line_matching(regex, line)
        end

        def append_if_no_line_matching(pattern, line)
          regex = pattern.is_a?(String) ? /#{Regexp.escape(pattern)}/ : pattern
          file_contents.push(line + "\n") if file_contents.grep(regex).empty?
        end

        def append_after_line_matching(pattern, line)
          regex = pattern.is_a?(String) ? /#{Regexp.escape(pattern)}/ : pattern
          i = file_contents.find_index { |l| l =~ regex }
          return unless i
          return if file_contents.size > i + 1 && file_contents[i + 1] == line
          file_contents.insert(i + 1, line + "\n")
        end

        # FIXME: should this be replace lines?
        def insert_between_lines_matching(line, start:, finish:)
        end

        def prepend_if_no_such_line(line)
          regex = /^#{Regexp.escape(line)}$/
          prepend_if_no_line_matching(regex, line)
        end

        def prepend_if_no_line_matching(pattern, line)
          regex = pattern.is_a?(String) ? /#{Regexp.escape(pattern)}/ : pattern
          file_contents.unshift(line + "\n") if file_contents.grep(regex).empty?
        end

        def prepend_before_line_matching(pattern, line)
          regex = pattern.is_a?(String) ? /#{Regexp.escape(pattern)}/ : pattern
          i = file_contents.find_index { |l| l =~ regex }
          return unless i
          i = 1 if i == 0
          return if file_contents[i - 1] == line
          file_contents.insert(i - 1, line + "\n")
        end

        def delete_lines_matching(pattern)
          regex = pattern.is_a?(String) ? /#{Regexp.escape(pattern)}/ : pattern
          file_contents.reject! { |l| l =~ regex }
        end

        def substitute_lines(pattern, replace, global: false)
          regex = pattern.is_a?(String) ? /#{Regexp.escape(pattern)}/ : pattern
          if global
            file_contents.each { |l| l.gsub(regex, replace) }
          else
            file_contents.each { |l| l.sub(regex, replace) }
          end
        end

        def substitution_block(start:, finish:, match:, replace:, global: false)
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

        def delete_block(start:, finish:)
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

        # NOTE: This is intented to be used only on a tempfile so we open, truncate and append
        # because the file provider already has the machinery to atomically move a tempfile into place.
        # If we crash in the middle it doesn't matter if we leave a corrupted tempfile to be
        # garbage collected as ruby exits.  If you feel you need to add atomicity here you probably
        # want to use a file provider directly or fix your own code to provide a tempfile to this
        # one and handle the atomicity yourself.
        #
        # This is not intended as a DSL method for end users.
        #
        # @api private
        def finish!
          ::File.open(path, "w") do |f|
            f.write file_contents.join
          end
        end
      end
    end
  end
end
