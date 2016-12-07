#
# Author:: Seth Falcon (<seth@chef.io>)
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

require "yaml"
require "chef/json_compat"
require "openssl"
require "base64"
require "digest/sha2"
require "chef/encrypted_data_bag_item"
require "chef/encrypted_data_bag_item/unsupported_encrypted_data_bag_item_format"
require "chef/encrypted_data_bag_item/decryption_failure"
require "chef/encrypted_data_bag_item/assertions"

class Chef::EncryptedDataBagItem

  #=== Decryptor
  # For backwards compatibility, Chef implements decryption/deserialization for
  # older encrypted data bag item formats in addition to the current version.
  # Each decryption/deserialization strategy is implemented as a class in this
  # namespace. For convenience the factory method +Decryptor.for()+ can be used
  # to create an instance of the appropriate strategy for the given encrypted
  # data bag value.
  module Decryptor
    extend Chef::EncryptedDataBagItem::Assertions

    # Detects the encrypted data bag item format version and instantiates a
    # decryptor object for that version. Call #for_decrypted_item on the
    # resulting object to decrypt and deserialize it.
    def self.for(encrypted_value, key)
      format_version = format_version_of(encrypted_value)
      assert_format_version_acceptable!(format_version)
      case format_version
      when 3
        Version3Decryptor.new(encrypted_value, key)
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

    class Version0Decryptor
      include Chef::EncryptedDataBagItem::Assertions

      attr_reader :encrypted_data
      attr_reader :key

      def initialize(encrypted_data, key)
        @encrypted_data = encrypted_data
        @key = key
      end

      # Returns the used decryption algorithm
      def algorithm
        ALGORITHM
      end

      def for_decrypted_item
        YAML.load(decrypted_data)
      end

      def decrypted_data
        @decrypted_data ||= begin
          plaintext = openssl_decryptor.update(encrypted_bytes)
          plaintext << openssl_decryptor.final
        rescue OpenSSL::Cipher::CipherError => e
          # if the key length is less than 255 characters, and it contains slashes, we think it may be a path.
          raise DecryptionFailure, "Error decrypting data bag value: '#{e.message}'. Most likely the provided key is incorrect. #{(@key.length < 255 && @key.include?('/')) ? 'You may need to use --secret-file rather than --secret.' : ''}"
        end
      end

      def encrypted_bytes
        Base64.decode64(@encrypted_data)
      end

      def openssl_decryptor
        @openssl_decryptor ||= begin
          d = OpenSSL::Cipher.new(algorithm)
          d.decrypt
          d.pkcs5_keyivgen(key)
          d
        end
      end
    end

    class Version1Decryptor < Version0Decryptor

      attr_reader :encrypted_data
      attr_reader :key

      def initialize(encrypted_data, key)
        @encrypted_data = encrypted_data
        @key = key
      end

      def for_decrypted_item
        Chef::JSONCompat.parse(decrypted_data)["json_wrapper"]
      rescue Chef::Exceptions::JSON::ParseError
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
          # if the key length is less than 255 characters, and it contains slashes, we think it may be a path.
          raise DecryptionFailure, "Error decrypting data bag value: '#{e.message}'. Most likely the provided key is incorrect. #{( @key.length < 255 && @key.include?('/')) ? 'You may need to use --secret-file rather than --secret.' : ''}"
        end
      end

      def openssl_decryptor
        @openssl_decryptor ||= begin
          assert_valid_cipher!(@encrypted_data["cipher"], algorithm)
          d = OpenSSL::Cipher.new(algorithm)
          d.decrypt
          # We must set key before iv: https://bugs.ruby-lang.org/issues/8221
          d.key = OpenSSL::Digest::SHA256.digest(key)
          d.iv = iv
          d
        end
      end

    end

    class Version2Decryptor < Version1Decryptor

      def decrypted_data
        validate_hmac! unless @decrypted_data
        super
      end

      def validate_hmac!
        digest = OpenSSL::Digest.new("sha256")
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

    class Version3Decryptor < Version1Decryptor

      def initialize(encrypted_data, key)
        super
        assert_aead_requirements_met!(algorithm)
      end

      # Returns the used decryption algorithm
      def algorithm
        AEAD_ALGORITHM
      end

      def auth_tag
        auth_tag_b64 = @encrypted_data["auth_tag"]
        if auth_tag_b64.nil?
          raise DecryptionFailure, "Error decrypting data bag value: invalid authentication tag. Most likely the data is corrupted"
        end
        Base64.decode64(auth_tag_b64)
      end

      def openssl_decryptor
        @openssl_decryptor ||= begin
          d = super
          d.auth_tag = auth_tag
          d.auth_data = ""
          d
        end
      end

    end

  end
end
