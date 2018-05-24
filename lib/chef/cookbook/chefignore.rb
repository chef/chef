#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2011-2016, Chef Software Inc.
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
  class Cookbook
    class Chefignore

      COMMENTS_AND_WHITESPACE = /^\s*(?:#.*)?$/

      attr_reader :ignores

      def initialize(ignore_file_or_repo)
        # Check the 'ignore_file_or_repo' path first and then look in the parent directories (up to 2 levels)
        # to handle both the chef repo cookbook layout and a standalone cookbook
        @ignore_file = find_ignore_file(ignore_file_or_repo)
        @ignores = parse_ignore_file
      end

      # @param [Array] file_list the list of cookbook files
      # @return [Array] list of cookbook files with chefignore files removed
      def remove_ignores_from(file_list)
        Array(file_list).inject([]) do |unignored, file|
          ignored?(file) ? unignored : unignored << file
        end
      end

      # @param [String] file_name the file name to check ignored status for
      # @return [Boolean] is the file ignored or not
      def ignored?(file_name)
        @ignores.any? { |glob| File.fnmatch?(glob, file_name) }
      end

      private

      def parse_ignore_file
        ignore_globs = []
        if readable_file_or_symlink?(@ignore_file)
          File.foreach(@ignore_file) do |line|
            ignore_globs << line.strip unless line =~ COMMENTS_AND_WHITESPACE
          end
        else
          Chef::Log.debug("No chefignore file found. No files will be ignored!")
        end
        ignore_globs
      end

      def find_ignore_file(path)
        ignore_path = path
        ignore_file = ''
        3.times do |i|
          if File.basename(ignore_path) =~ /chefignore/
            ignore_file = ignore_path
          else
            ignore_file = File.join(ignore_path, "/chefignore")
          end
          if readable_file_or_symlink?(ignore_file)
            break
          else
            Chef::Log.debug("No chefignore file found at #{ignore_path}.")
            ignore_path = File.dirname(ignore_path) unless i == 2
          end
        end
        ignore_file
      end

      def readable_file_or_symlink?(path)
        File.exist?(path) && File.readable?(path) &&
          (File.file?(path) || File.symlink?(path))
      end
    end
  end
end
