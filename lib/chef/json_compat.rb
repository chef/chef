#
# Author:: Tim Hinderliter (<tim@chef.io>)
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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

# Wrapper class for interacting with JSON.

require "ffi_yajl"
require "chef/exceptions"
# We're requiring this to prevent breaking consumers using Hash.to_json
require "json"

class Chef
  class JSONCompat
    JSON_MAX_NESTING = 1000

    class <<self

      # API to use to avoid create_addtions
      def parse(source, opts = {})
        FFI_Yajl::Parser.parse(source, opts)
      rescue FFI_Yajl::ParseError => e
        raise Chef::Exceptions::JSON::ParseError, e.message
      end

      # Just call the JSON gem's parse method with a modified :max_nesting field
      def from_json(source, opts = {})
        obj = parse(source, opts)

        # JSON gem requires top level object to be a Hash or Array (otherwise
        # you get the "must contain two octets" error). Yajl doesn't impose the
        # same limitation. For compatibility, we re-impose this condition.
        unless obj.kind_of?(Hash) || obj.kind_of?(Array)
          raise Chef::Exceptions::JSON::ParseError, "Top level JSON object must be a Hash or Array. (actual: #{obj.class})"
        end

        obj
      end

      def to_json(obj, opts = nil)
        FFI_Yajl::Encoder.encode(obj, opts)
      rescue FFI_Yajl::EncodeError => e
        raise Chef::Exceptions::JSON::EncodeError, e.message
      end

      def to_json_pretty(obj, opts = nil)
        opts ||= {}
        options_map = {}
        options_map[:pretty] = true
        options_map[:indent] = opts[:indent] if opts.has_key?(:indent)
        to_json(obj, options_map).chomp
      end

    end
  end
end
