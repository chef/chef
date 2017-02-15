#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

class Chef
  module Mixin
    module CreatePath

      # Creates a given path, including all directories that lead up to it.
      # Like mkdir_p, but without the leaking.
      #
      # === Parameters
      # file_path<String, Array>:: A string that represents the path to create,
      #   or an Array with the path-parts.
      #
      # === Returns
      # The created file_path.
      def create_path(file_path)
        unless file_path.kind_of?(String) || file_path.kind_of?(Array)
          raise ArgumentError, "file_path must be a string or an array!"
        end

        if file_path.kind_of?(String)
          file_path = File.expand_path(file_path).split(File::SEPARATOR)
          file_path.shift if file_path[0] == ""
          # Check if path starts with a separator or drive letter (Windows)
          unless file_path[0].match("^#{File::SEPARATOR}|^[a-zA-Z]:")
            file_path[0] = "#{File::SEPARATOR}#{file_path[0]}"
          end
        end

        file_path.each_index do |i|
          create_path = File.join(file_path[0, i + 1])
          create_dir(create_path) unless File.directory?(create_path)
        end

        File.expand_path(File.join(file_path))
      end

      private

      def create_dir(path)
          # When doing multithreaded downloads into the file cache, the following
          # interleaving raises an error here:
          #
          # thread1                                     thread2
          # File.directory?(create_path) <- false
          #                                             File.directory?(create_path) <- false
          #                                             Dir.mkdir(create_path)
          # Dir.mkdir(create_path) <- raises Errno::EEXIST
        Chef::Log.debug("Creating directory #{path}")
        Dir.mkdir(path)
      rescue Errno::EEXIST
      end

    end
  end
end
