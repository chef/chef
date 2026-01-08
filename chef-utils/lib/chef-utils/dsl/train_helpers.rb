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

require "stringio" unless defined?(StringIO)
require_relative "../internal"

module ChefUtils
  module DSL
    module TrainHelpers
      include Internal

      #
      # FIXME: generally these helpers all use the pattern of checking for target_mode?
      # and then if it is we use train.  That approach should likely be flipped so that
      # even when we're running without target mode we still use train in its local
      # mode.  A prerequisite for that will be better CI testing of train against
      # chef-client though, and ensuring that the APIs are entirely compatible.  This
      # will be particularly problematic for shell_out APIs and eventual file-creating
      # APIs which are unlikely to be as sophisticated as the exiting code in chef-client
      # for locally shelling out and creating files, and just dropping inspec local mode
      # into chef-client would break the world.
      #

      # Train wrapper around File.exist? to make it local mode aware.
      #
      # @param filename filename to check
      # @return [Boolean] if it exists
      #
      def file_exist?(filename)
        if __transport_connection
          __transport_connection.file(filename).exist?
        else
          File.exist?(filename)
        end
      end

      # XXX: modifications to the StringIO won't get written back
      # FIXME: this is very experimental and may be a bad idea and may break at any time
      # @api private
      #
      def file_open(*args, &block)
        if __transport_connection
          content = __transport_connection.file(args[0]).content
          string_io = StringIO.new content
          yield string_io if block_given?
          string_io
        else
          File.open(*args, &block)
        end
      end

      # Alias to easily convert IO.read / File.read to file_read
      def file_read(path)
        file_open(path).read
      end

      def file_directory?(path)
        if __transport_connection
          __transport_connection.file(filename).directory?
        else
          File.directory?(path)
        end
      end

      # Alias to easily convert Dir.exist to dir_exist
      def dir_exist?(path)
        file_directory?(path)
      end

      extend self
    end
  end
end
