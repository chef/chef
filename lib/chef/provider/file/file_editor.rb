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

        def delete_lines_matching(pattern)
          regex = pattern.is_a?(String) ? /#{Regexp.escape(pattern)}/ : pattern
          file_contents.reject! { |l| l =~ regex }
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
