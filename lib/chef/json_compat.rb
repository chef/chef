#
# Author:: Tim Hinderliter (<tim@chef.io>)
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

# Wrapper class for interacting with JSON.

autoload :FFI_Yajl, "ffi_yajl"
require_relative "exceptions"
# We're requiring this to prevent breaking consumers using Hash.to_json
require "json" unless defined?(JSON)

class Chef
  class JSONCompat

    class << self

      def parse(source, opts = {})
        FFI_Yajl::Parser.parse(source, opts)
      rescue FFI_Yajl::ParseError => e
        raise Chef::Exceptions::JSON::ParseError, e.message
      end

      def from_json(source, opts = {})
        obj = parse(source, opts)

        # JSON gem requires top level object to be a Hash or Array (otherwise
        # you get the "must contain two octets" error). Yajl doesn't impose the
        # same limitation. For compatibility, we re-impose this condition.
        unless obj.is_a?(Hash) || obj.is_a?(Array)
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
        options_map = { pretty: true }
        options_map[:indent] = opts[:indent] if opts.respond_to?(:key?) && opts.key?(:indent)
        to_json(obj, options_map).chomp
      end

    end
  end
end
