#
# Author:: Chris Bandy (<bandy.chris@gmail.com>)
# Copyright:: Copyright (c) 2014 Opscode, Inc.
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
    class Editor
      attr_reader :lines

      def initialize(lines)
        @lines = lines.to_a.clone
      end

      def append_line_after(search, line_to_append)
        lines = []

        @lines.each do |line|
          lines << line
          lines << line_to_append if line.match(search)
        end

        (lines.length - @lines.length).tap { @lines = lines }
      end

      def append_line_if_missing(search, line_to_append)
        when_missing_line(search) do
          @lines << line_to_append
        end
      end

      def prepend_line_if_missing(search, line_to_prepend)
        when_missing_line(search) do
          @lines.unshift line_to_prepend
        end
      end

      def remove_lines(search)
        count = 0

        @lines.delete_if do |line|
          count += 1 if line.match(search)
        end

        count
      end

      def replace(search, replace)
        count = 0

        @lines.map! do |line|
          if line.match(search)
            count += 1
            line.gsub!(search, replace)
          else
            line
          end
        end

        count
      end

      def replace_lines(search, replace)
        count = 0

        @lines.map! do |line|
          if line.match(search)
            count += 1
            replace
          else
            line
          end
        end

        count
      end

      private

      def when_missing_line(line, &block)
        count = 0 
        if missing_line?(line)
          count = 1
          block.call
        end
        count
      end

      def missing_line?(searched_line)
        ! @lines.find { |line| line.match(searched_line) }
      end
      
    end
  end
end

