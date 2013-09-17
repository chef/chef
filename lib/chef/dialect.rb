#
# Copyright:: Copyright (c) 2013 Noah Kantrowitz <noah@coderanger.net>
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

require 'chef/exceptions'

class Chef
  class Dialect

    # Class methods to handle registering and finding dialects
    class << self
      def dialects
        @dialects ||= []
      end

      def register_dialect(flavor, extension, mime_type, quality=1)
        Chef::Dialect.dialects << {:extension => extension, :mime_type => mime_type, :quality => quality, :flavor => flavor, :dialect => self.new}
      end

      def find_by_extension(flavor, extension)
        # Allow passing in a full file path for ease-of-use
        extension = File.basename(extension)
        extname = File.extname(extension)
        extension = extname if extname != ''
        find {|d| d[:flavor] == flavor && d[:extension] == extension}
      end

      def find_by_mime_type(flavor, mime_type)
        find {|d| d[:flavor] == flavor && d[:mime_type] == mime_type}
      end

      private

      def find(&block)
        candidates = dialects.select(&block)
        raise Chef::Exceptions::DialectNotFound.new("No matching dialect found") if candidates.empty?
        candidates.max_by{|d| d[:quality]}[:dialect]
      end
    end
  end
end

