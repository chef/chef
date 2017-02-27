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

require "base64"
require "digest/sha2"
require "openssl"
require "ffi_yajl"
require "chef/encrypted_data_bag_item"
require "chef/encrypted_data_bag_item/unsupported_encrypted_data_bag_item_format"
require "chef/encrypted_data_bag_item/encryption_failure"
require "chef/encrypted_data_bag_item/assertions"

class Chef::EncryptedDataBagItem

  # Implementation class for converting plaintext data bag item values to an
  # encrypted value, including any necessary wrappers and metadata.
  module Encryptor

    # "factory" method that creates an encryptor object with the proper class
    # for the desired encrypted data bag format version.
    #
    # +Chef::Config[:data_bag_encrypt_version]+ determines which version is used.
    def self.new(value, secret, iv = nil)
      format_version = Chef::Config[:data_bag_encrypt_version]
      case format_version
      when 1
        Version1Encryptor.new(value, secret, iv)
      when 2
        Version2Encryptor.new(value, secret, iv)
      when 3
        Version3Encryptor.new(value, secret, iv)
      else
        raise UnsupportedEncryptedDataBagItemFormat,
          "Invalid encrypted data bag format version `#{format_version}'. Supported versions are '1', '2', '3'"
      end
    end

    class Version1Encryptor
      attr_reader :key
      attr_reader :plaintext_data

      include Chef::EncryptedDataBagItem::Assertions

      # Create a new Encryptor for +data+, which will be encrypted with the given
      # +key+.
      #
      # === Arguments:
      # * data: An object of any type that can be serialized to json
      # * key: A String representing the desired passphrase
      # * iv: The optional +iv+ parameter is intended for testing use only. When
      # *not* supplied, Encryptor will use OpenSSL to generate a secure random
      # IV, which is what you want.
      def initialize(plaintext_data, key, iv = nil)
        @plaintext_data = plaintext_data
        @key = key
        @iv = iv && Base64.decode64(iv)
      end

      # Returns the used encryption algorithm
      def algorithm
        ALGORITHM
      end

      # Returns a wrapped and encrypted version of +plaintext_data+ suitable for
      # using as the value in an encrypted data bag item.
      def for_encrypted_item
        {
          "encrypted_data" => encrypted_data,
          "iv" => Base64.encode64(iv),
          "version" => 1,
          "cipher" => algorithm,
        }
      end

      # Generates or returns the IV.
      def iv
        # Generated IV comes from OpenSSL::Cipher#random_iv
        # This gets generated when +openssl_encryptor+ gets created.
        openssl_encryptor if @iv.nil?
        @iv
      end

      # Generates (and memoizes) an OpenSSL::Cipher object and configures
      # it for the specified iv and encryption key.
      def openssl_encryptor
        @openssl_encryptor ||= begin
          encryptor = OpenSSL::Cipher.new(algorithm)
          encryptor.encrypt
          # We must set key before iv: https://bugs.ruby-lang.org/issues/8221
          encryptor.key = OpenSSL::Digest::SHA256.digest(key)
          @iv ||= encryptor.random_iv
          encryptor.iv = @iv
          encryptor
        end
      end

      # Encrypts and Base64 encodes +serialized_data+
      def encrypted_data
        @encrypted_data ||= begin
          enc_data = openssl_encryptor.update(serialized_data)
          enc_data << openssl_encryptor.final
          Base64.encode64(enc_data)
        end
      end

      # Wraps the data in a single key Hash (JSON Object) and converts to JSON.
      # The wrapper is required because we accept values (such as Integers or
      # Strings) that do not produce valid JSON when serialized without the
      # wrapper.
      def serialized_data
        FFI_Yajl::Encoder.encode(:json_wrapper => plaintext_data)
      end

      def self.encryptor_keys
        %w{ encrypted_data iv version cipher }
      end
    end

    class Version2Encryptor < Version1Encryptor

      # Returns a wrapped and encrypted version of +plaintext_data+ suitable for
      # using as the value in an encrypted data bag item.
      def for_encrypted_item
        {
          "encrypted_data" => encrypted_data,
          "hmac" => hmac,
          "iv" => Base64.encode64(iv),
          "version" => 2,
          "cipher" => algorithm,
        }
      end

      # Generates an HMAC-SHA2-256 of the encrypted data (encrypt-then-mac)
      def hmac
        @hmac ||= begin
          digest = OpenSSL::Digest.new("sha256")
          raw_hmac = OpenSSL::HMAC.digest(digest, key, encrypted_data)
          Base64.encode64(raw_hmac)
        end
      end

      def self.encryptor_keys
        super + %w{ hmac }
      end
    end

    class Version3Encryptor < Version1Encryptor
      include Chef::EncryptedDataBagItem::Assertions

      def initialize(plaintext_data, key, iv = nil)
        super
        assert_aead_requirements_met!(algorithm)
        @auth_tag = nil
      end

      # Returns a wrapped and encrypted version of +plaintext_data+ suitable for
      # using as the value in an encrypted data bag item.
      def for_encrypted_item
        {
          "encrypted_data" => encrypted_data,
          "iv" => Base64.encode64(iv),
          "auth_tag" => Base64.encode64(auth_tag),
          "version" => 3,
          "cipher" => algorithm,
        }
      end

      # Returns the used encryption algorithm
      def algorithm
        AEAD_ALGORITHM
      end

      # Returns a wrapped and encrypted version of +plaintext_data+ suitable for
      # Returns the auth_tag.
      def auth_tag
        # Generated auth_tag comes from OpenSSL::Cipher#auth_tag
        # This must be generated after the data is encrypted
        if @auth_tag.nil?
          raise EncryptionFailure, "Internal Error: GCM authentication tag read before encryption"
        end
        @auth_tag
      end

      # Generates (and memoizes) an OpenSSL::Cipher object and configures
      # it for the specified iv and encryption key using AEAD
      def openssl_encryptor
        @openssl_encryptor ||= begin
          encryptor = super
          encryptor.auth_data = ""
          encryptor
        end
      end

      # Encrypts, Base64 encodes +serialized_data+ and gets the authentication tag
      def encrypted_data
        @encrypted_data ||= begin
          enc_data_b64 = super
          @auth_tag = openssl_encryptor.auth_tag
          enc_data_b64
        end
      end

      def self.encryptor_keys
        super + %w{ auth_tag }
      end

    end

  end
end
