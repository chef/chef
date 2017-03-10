#
# Author:: Tyler Ball (<tball@chef.io>)
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
#

require "chef/encrypted_data_bag_item/encryptor"

class Chef::EncryptedDataBagItem
  # Common code for checking if a data bag appears encrypted
  module CheckEncrypted

    # Tries to autodetect if the item's raw hash appears to be encrypted.
    def encrypted?(raw_data)
      data = raw_data.reject { |k, _| k == "id" } # Remove the "id" key.
      # Assume hashes containing only the "id" key are not encrypted.
      # Otherwise, remove the keys that don't appear to be encrypted and compare
      # the result with the hash. If some entry has been removed, then some entry
      # doesn't appear to be encrypted and we assume the entire hash is not encrypted.
      data.empty? ? false : data.reject { |_, v| !looks_like_encrypted?(v) } == data
    end

    private

    # Checks if data looks like it has been encrypted by
    # Chef::EncryptedDataBagItem::Encryptor::VersionXEncryptor. Returns
    # true only when there is an exact match between the VersionXEncryptor
    # keys and the hash's keys.
    def looks_like_encrypted?(data)
      return false unless data.is_a?(Hash) && data.has_key?("version")
      case data["version"]
        when 1
          Chef::EncryptedDataBagItem::Encryptor::Version1Encryptor.encryptor_keys.sort == data.keys.sort
        when 2
          Chef::EncryptedDataBagItem::Encryptor::Version2Encryptor.encryptor_keys.sort == data.keys.sort
        when 3
          Chef::EncryptedDataBagItem::Encryptor::Version3Encryptor.encryptor_keys.sort == data.keys.sort
        else
          false # version means something else... assume not encrypted.
      end
    end

  end
end
