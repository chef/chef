#
# Author:: Jay Mundrawala (<jdm@chef.io>)
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

require_relative "error"
require_relative "api/memory"
require_relative "api/crypto"
require_relative "unicode"
require "digest" unless defined?(Digest)

class Chef
  module ReservedNames::Win32
    class Crypto
      include Chef::ReservedNames::Win32::API::Crypto
      extend Chef::ReservedNames::Win32::API::Crypto

      def self.encrypt(str, &block)
        data_blob = CRYPT_INTEGER_BLOB.new
        unless CryptProtectData(CRYPT_INTEGER_BLOB.new(str.to_wstring), nil, nil, nil, nil, CRYPTPROTECT_LOCAL_MACHINE, data_blob)
          Chef::ReservedNames::Win32::Error.raise!
        end
        bytes = data_blob[:pbData].get_bytes(0, data_blob[:cbData])
        if block
          block.call(bytes)
        else
          Digest.hexencode(bytes)
        end
      ensure
        unless data_blob[:pbData].null?
          Chef::ReservedNames::Win32::Memory.local_free(data_blob[:pbData])
        end
      end

    end
  end
end
