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

require_relative "../path_helper"

module ChefConfig
  module Mixin
    module DotD
      # Find available configuration files in a `.d/` style include directory.
      # Only top-level `*.rb` files are considered (no recursive traversal).
      # Files are returned in deterministic lexical order.
      # Make sure we exclude anything that's not a file so we avoid directories ending in .rb (just in case).
      #
      # @api internal
      # @param path [String] Base .d/ path to load from.
      # @return [Array<String>]
      def find_dot_d(path)
        dot_d_entries(path).select { |entry| File.file?(entry) }.sort
      end

      # Load configuration from a `.d/` style include directory.
      # Exceptions from apply_config are allowed to bubble up to the caller.
      #
      # @api internal
      # @param path [String] Base .d/ path to load from.
      # @return [void]
      def load_dot_d(path)
        find_dot_d(path).each do |conf|
          apply_dot_d_config(conf)
        end
      end

      private

      def dot_d_entries(path)
        Dir[dot_d_glob(path)]
      end

      def dot_d_glob(path)
        "#{PathHelper.escape_glob_dir(path)}/*.rb"
      end

      def apply_dot_d_config(path)
        apply_config(IO.read(path), path)
      end
    end
  end
end
