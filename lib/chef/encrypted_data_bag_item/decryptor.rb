#
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright 2010-2011 Opscode, Inc.
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

require 'yaml'
require 'ffi_yajl'
require 'openssl'
require 'base64'
require 'digest/sha2'
require 'chef/encrypted_data_bag_item'
require 'chef/encrypted_data_bag_item/unsupported_encrypted_data_bag_item_format'
require 'chef/encrypted_data_bag_item/unacceptable_encrypted_data_bag_item_format'
require 'chef/encrypted_data_bag_item/decryption_failure'
require 'chef/encrypted_data_bag_item/unsupported_cipher'

class Chef::EncryptedDataBagItem

  #=== Decryptor
  # For backwards compatibility, Chef implements decryption/deserialization for
  # older encrypted data bag item formats in addition to the current version.
  # Each decryption/deserialization strategy is implemented as a class in this
  # namespace. For convenience the factory method +Decryptor.for()+ can be used
  # to create an instance of the appropriate strategy for the given encrypted
  # data bag value.
  module Decryptor

    # Detects the encrypted data bag item format version and instantiates a
    # decryptor object for that version. Call #for_decrypted_item on the
    # resulting object to decrypt and deserialize it.
    def self.for(encrypted_value, key)
      format_version = format_version_of(encrypted_value)
      assert_format_version_acceptable!(format_version)
      case format_version
      when 2
        Version2Decryptor.new(encrypted_value, key)
      when 1
        Version1Decryptor.new(encrypted_value, key)
      when 0
        Version0Decryptor.new(encrypted_value, key)
      else
        raise UnsupportedEncryptedDataBagItemFormat,
          "This version of chef does not support encrypted data bag item format version '#{format_version}'"
      end
    end

    def self.format_version_of(encrypted_value)
      if encrypted_value.respond_to?(:key?)
        encrypted_value["version"]
      else
        0
      end
    end

    def self.assert_format_version_acceptable!(format_version)
      unless format_version.kind_of?(Integer) and format_version >= Chef::Config[:data_bag_decrypt_minimum_version]
        raise UnacceptableEncryptedDataBagItemFormat,
          "The encrypted data bag item has format version `#{format_version}', " +
          "but the config setting 'data_bag_decrypt_minimum_version' requires version `#{Chef::Config[:data_bag_decrypt_minimum_version]}'"
      end
    end

    class Version0Decryptor

      attr_reader :encrypted_data
      attr_reader :key

      def initialize(encrypted_data, key)
        @encrypted_data = encrypted_data
        @key = key
      end

      def for_decrypted_item
        YAML.load(decrypted_data)
      end

      def decrypted_data
        @decrypted_data ||= begin
          plaintext = openssl_decryptor.update(encrypted_bytes)
          plaintext << openssl_decryptor.final
        rescue OpenSSL::Cipher::CipherError => e
          raise DecryptionFailure, "Error decrypting data bag value: '#{e.message}'. Most likely the provided key is incorrect"
        end
      end

      def encrypted_bytes
        Base64.decode64(@encrypted_data)
      end

      def openssl_decryptor
        @openssl_decryptor ||= begin
          d = OpenSSL::Cipher::Cipher.new(ALGORITHM)
          d.decrypt
          d.pkcs5_keyivgen(key)
          d
        end
      end
    end

    class Version1Decryptor

      attr_reader :encrypted_data
      attr_reader :key

      def initialize(encrypted_data, key)
        @encrypted_data = encrypted_data
        @key = key
      end

      def for_decrypted_item
        FFI_Yajl::Parser.parse(decrypted_data)["json_wrapper"]
      rescue FFI_Yajl::ParseError
        # convert to a DecryptionFailure error because the most likely scenario
        # here is that the decryption step was unsuccessful but returned bad
        # data rather than raising an error.
        raise DecryptionFailure, "Error decrypting data bag value. Most likely the provided key is incorrect"
      end

      def encrypted_bytes
        Base64.decode64(@encrypted_data["encrypted_data"])
      end

      def iv
        Base64.decode64(@encrypted_data["iv"])
      end

      def decrypted_data
        @decrypted_data ||= begin
          plaintext = openssl_decryptor.update(encrypted_bytes)
          plaintext << openssl_decryptor.final
        rescue OpenSSL::Cipher::CipherError => e
          raise DecryptionFailure, "Error decrypting data bag value: '#{e.message}'. Most likely the provided key is incorrect"
        end
      end

      def openssl_decryptor
        @openssl_decryptor ||= begin
          assert_valid_cipher!
          d = OpenSSL::Cipher::Cipher.new(ALGORITHM)
          d.decrypt
          d.key = Digest::SHA256.digest(key)
          d.iv = iv
          d
        end
      end

      def assert_valid_cipher!
        # In the future, chef may support configurable ciphers. For now, only
        # aes-256-cbc is supported.
        requested_cipher = @encrypted_data["cipher"]
        unless requested_cipher == ALGORITHM
          raise UnsupportedCipher,
            "Cipher '#{requested_cipher}' is not supported by this version of Chef. Available ciphers: ['#{ALGORITHM}']"
        end
      end
    end

    class Version2Decryptor < Version1Decryptor

      def decrypted_data
        validate_hmac! unless @decrypted_data
        super
      end

      def validate_hmac!
        digest = OpenSSL::Digest::Digest.new("sha256")
        raw_hmac = OpenSSL::HMAC.digest(digest, key, @encrypted_data["encrypted_data"])

        if candidate_hmac_matches?(raw_hmac)
          true
        else
          raise DecryptionFailure, "Error decrypting data bag value: invalid hmac. Most likely the provided key is incorrect"
        end
      end

      private

      def candidate_hmac_matches?(expected_hmac)
        return false unless @encrypted_data["hmac"]
        expected_bytes = expected_hmac.bytes.to_a
        candidate_hmac_bytes = Base64.decode64(@encrypted_data["hmac"]).bytes.to_a
        valid = expected_bytes.size ^ candidate_hmac_bytes.size
        expected_bytes.zip(candidate_hmac_bytes) { |x, y| valid |= x ^ y.to_i }
        valid == 0
      end
    end
  end
end
