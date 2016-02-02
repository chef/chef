#
# Author:: Nuo Yan (<nuo@chef.io>)
# Copyright:: Copyright 2009-2016, Chef Software Inc.
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

require "chef/util/editor"
require "fileutils"

class Chef
  class Util
    class FileEdit

      private

      attr_reader :editor, :original_pathname

      public

      def initialize(filepath)
        raise ArgumentError, "File '#{filepath}' does not exist" unless File.exist?(filepath)
        @editor = Editor.new(File.open(filepath, &:readlines))
        @original_pathname = filepath
        @file_edited = false
      end

      # return if file has been edited
      def file_edited?
        @file_edited
      end

      #search the file line by line and match each line with the given regex
      #if matched, replace the whole line with newline.
      def search_file_replace_line(regex, newline)
        @changes = (editor.replace_lines(regex, newline) > 0) || @changes
      end

      #search the file line by line and match each line with the given regex
      #if matched, replace the match (all occurrences)  with the replace parameter
      def search_file_replace(regex, replace)
        @changes = (editor.replace(regex, replace) > 0) || @changes
      end

      #search the file line by line and match each line with the given regex
      #if matched, delete the line
      def search_file_delete_line(regex)
        @changes = (editor.remove_lines(regex) > 0) || @changes
      end

      #search the file line by line and match each line with the given regex
      #if matched, delete the match (all occurrences) from the line
      def search_file_delete(regex)
        search_file_replace(regex, "")
      end

      #search the file line by line and match each line with the given regex
      #if matched, insert newline after each matching line
      def insert_line_after_match(regex, newline)
        @changes = (editor.append_line_after(regex, newline) > 0) || @changes
      end

      #search the file line by line and match each line with the given regex
      #if not matched, insert newline at the end of the file
      def insert_line_if_no_match(regex, newline)
        @changes = (editor.append_line_if_missing(regex, newline) > 0) || @changes
      end

      def unwritten_changes?
        !!@changes
      end

      #Make a copy of old_file and write new file out (only if file changed)
      def write_file
        if @changes
          backup_pathname = original_pathname + ".old"
          FileUtils.cp(original_pathname, backup_pathname, :preserve => true)
          File.open(original_pathname, "w") do |newfile|
            editor.lines.each do |line|
              newfile.puts(line)
            end
            newfile.flush
          end
          @file_edited = true
        end
        @changes = false
      end
    end
  end
end
