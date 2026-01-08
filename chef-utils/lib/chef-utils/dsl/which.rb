# frozen_string_literal: true
#
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

require_relative "../internal"

module ChefUtils
  module DSL
    module Which
      include Internal

      # Lookup an executable through the systems search PATH.  Allows specifying an array
      # of executables to look for.  The first executable that is found, along any path entry,
      # will be the preferred one and returned first.  The extra_path will override any default
      # extra_paths which are added (allowing the user to pass an empty array to remove them).
      #
      # When passed a block the block will be called with the full pathname of any executables
      # which are found, and the block should return truthy or falsey values to further filter
      # the executable based on arbitrary criteria.
      #
      # This is syntactic sugar for `where(...).first`
      #
      # This helper can be used in target mode in chef or with train using the appropriate
      # wiring externally.
      #
      # @example Find the most appropriate python executable, searching through the system PATH
      #          plus additionally the "/usr/libexec" directory, which has the dnf libraries
      #          installed and available.
      #
      #   cmd = which("platform-python", "python", "python3", "python2", "python2.7", extra_path: "/usr/libexec") do |f|
      #     shell_out("#{f} -c 'import dnf'").exitstatus == 0
      #   end
      #
      # @param [Array<String>] list of commands to search for
      # @param [String,Array<String>] array of paths to look in first
      # @param [String,Array<String>] array of extra paths to search through
      # @return [String] the first match
      #
      def which(*cmds, prepend_path: nil, extra_path: nil, &block)
        where(*cmds, prepend_path: prepend_path, extra_path: extra_path, &block).first || false
      end

      # Lookup all the instances of an an executable that can be found through the systems search PATH.
      # Allows specifying an array of executables to look for.  All the instances of the first executable
      # that is found will be returned first.  The extra_path will override any default extra_paths
      # which are added (allowing the user to pass an empty array to remove them).
      #
      # When passed a block the block will be called with the full pathname of any executables
      # which are found, and the block should return truthy or falsey values to further filter
      # the executable based on arbitrary criteria.
      #
      # This helper can be used in target mode in chef or with train using the appropriate
      # wiring externally.
      #
      # @example Find all the python executables, searching through the system PATH plus additionally
      #          the "/usr/libexec" directory, which have the dnf libraries installed and available.
      #
      #   cmds = where("platform-python", "python", "python3", "python2", "python2.7", extra_path: "/usr/libexec") do |f|
      #     shell_out("#{f} -c 'import dnf'").exitstatus == 0
      #   end
      #
      # @param [Array<String>] list of commands to search for
      # @param [String,Array<String>] array of paths to look in first
      # @param [String,Array<String>] array of extra paths to search through
      # @return [String] the first match
      #
      def where(*cmds, prepend_path: nil, extra_path: nil, &block)
        extra_path ||= __extra_path
        paths = Array(prepend_path) + __env_path.split(File::PATH_SEPARATOR) + Array(extra_path)
        paths.uniq!
        exts = ENV["PATHEXT"] ? ENV["PATHEXT"].split(";") : []
        exts.unshift("")
        cmds.map do |cmd|
          paths.map do |path|
            exts.map do |ext|
              filename = File.join(path, "#{cmd}#{ext}")
              filename if __valid_executable?(filename, &block)
            end.compact
          end
        end.flatten
      end

      private

      # This is for injecting common extra_paths into the search PATH.  The chef-client codebase overrides this into its
      # own custom mixin to ensure that /usr/sbin, /sbin, etc are in the search PATH for chef-client.
      #
      # @api private
      def __extra_path
        nil
      end

      # Windows compatible and train/target-mode-enhanced helper to determine if an executable is valid.
      #
      # @api private
      def __valid_executable?(filename, &block)
        is_executable =
          if __transport_connection
            __transport_connection.file(filename).stat[:mode] & 1 && !__transport_connection.file(filename).directory?
          else
            File.executable?(filename) && !File.directory?(filename)
          end
        return false unless is_executable

        block ? yield(filename) : true
      end

      extend self
    end
  end
end
