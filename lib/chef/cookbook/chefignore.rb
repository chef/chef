# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
        # Check the 'ignore_file_or_repo' path first and then look in the parent directories till root
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
        if @ignore_file && readable_file_or_symlink?(@ignore_file)
          File.foreach(@ignore_file) do |line|
            unless COMMENTS_AND_WHITESPACE.match?(line)
              line.strip!
              ignore_globs << line
            end
          end
        else
          Chef::Log.debug("No chefignore file found. No files will be ignored!")
        end
        ignore_globs
      end

      # Lookup of chefignore file till the root dir of the provided path.
      # If file refer then lookup the parent dir till the root.
      # eg. path: /var/.chef/cookbook_name
      # Lookup at '/var/.chef/cookbook_name/chefignore', '/var/.chef/chefignore' '/var/chefignore' and '/chefignore' until exist
      def find_ignore_file(path)
        Pathname.new(path).ascend do |dir|
          next unless dir.directory?

          file = dir.join("chefignore")
          return file.expand_path.to_s if file.exist?
        end

        nil
      end

      def readable_file_or_symlink?(path)
        File.exist?(path) && File.readable?(path) &&
          (File.file?(path) || File.symlink?(path))
      end
    end
  end
end
