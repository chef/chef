#
# Copyright:: Copyright 2016, Chef Software Inc.
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

require "chef/config"
require "digest/md5"
require "openssl"

class Chef
  module Mixin
    module FIPS

      # When FIPS mode is enabled, yield to the block
      # with a working MD5 implementation.
      # @api private
      def with_fips_md5_exception
        allow_md5 if Chef::Config[:fips]

        begin
          yield
        ensure
          disallow_md5 if Chef::Config[:fips]
        end
      end

      # @api private
      def allow_md5
        Digest.const_set("MD5", Digest::MD5_)
        OpenSSL::Digest.const_set("MD5", Digest::MD5_)
      end

      # @api private
      def disallow_md5
        Digest.send(:remove_const, "MD5")
        OpenSSL::Digest.send(:remove_const, "MD5")
      end
    end
  end
end
