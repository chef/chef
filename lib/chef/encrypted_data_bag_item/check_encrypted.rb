#
# Author:: Tyler Ball (<tball@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "encryptor"

class Chef::EncryptedDataBagItem
  # Common code for checking if a data bag appears encrypted
  module CheckEncrypted
    #
    # Tries to autodetect if the item's raw hash appears to be encrypted.
    #
    # @param [Hash] raw_data The raw encrypted data bag hash
    #
    # @return [Boolean]
    #
    def encrypted?(raw_data)
      data = raw_data

      data.delete("id") # Remove the "id" key.

      # Assume hashes containing only the "id" key are not encrypted.
      return false if data.empty?

      # return false if any of the keys don't appear to be encrypted
      data.each_value do |v|
        return false unless looks_like_encrypted?(v)
      end

      return true
    end

    private

    #
    # Checks if data looks like it has been encrypted by
    # Chef::EncryptedDataBagItem::Encryptor::VersionXEncryptor. Returns
    # true only when
    #
    # @return [Boolean] There is an exact match between the VersionXEncryptor keys and the hash's keys.
    #
    def looks_like_encrypted?(data)
      return false unless data.is_a?(Hash) && data.key?("version")

      case data["version"]
        when 1
          %w{ cipher encrypted_data iv version } == data.keys.sort
        when 2
          %w{ cipher encrypted_data hmac iv version } == data.keys.sort
        when 3
          Chef::EncryptedDataBagItem::Encryptor::Version3Encryptor.encryptor_keys.sort == data.keys.sort
        else
          false # version means something else... assume not encrypted.
      end
    end

  end
end
