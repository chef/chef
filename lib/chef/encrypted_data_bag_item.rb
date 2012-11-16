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

require 'base64'
require 'openssl'
require 'chef/data_bag_item'
require 'yaml'
require 'yajl'
require 'open-uri'

# An EncryptedDataBagItem represents a read-only data bag item where
# all values, except for the value associated with the id key, have
# been encrypted.
#
# EncrypedDataBagItem can be used in recipes to decrypt data bag item
# members.
#
# Data bag item values are assumed to have been encrypted using the
# default symmetric encryption provided by Encryptor.encrypt where
# values are converted to YAML prior to encryption.
#
# If the shared secret is not specified at initialization or load,
# then the contents of the file referred to in
# Chef::Config[:encrypted_data_bag_secret] will be used as the
# secret.  The default path is /etc/chef/encrypted_data_bag_secret
#
# EncryptedDataBagItem is intended to provide a means to avoid storing
# data bag items in the clear on the Chef server.  This provides some
# protection against a breach of the Chef server or of Chef server
# backup data.  Because the secret must be stored in the clear on any
# node needing access to an EncryptedDataBagItem, this approach
# provides no protection of data bag items from actors with access to
# such nodes in the infrastructure.
#
class Chef::EncryptedDataBagItem
  DEFAULT_SECRET_FILE = "/etc/chef/encrypted_data_bag_secret"
  ALGORITHM = 'aes-256-cbc'

  class UnsupportedEncryptedDataBagItemFormat < StandardError
  end

  class DecryptionFailure < StandardError
  end

  class UnsupportedCipher < StandardError
  end

  # Implementation class for converting plaintext data bag item values to an
  # encrypted value, including any necessary wrappers and metadata.
  class Encryptor

    attr_reader :key
    attr_reader :plaintext_data

    # Create a new Encryptor for +data+, which will be encrypted with the given
    # +key+.
    #
    # === Arguments:
    # * data: An object of any type that can be serialized to json
    # * key: A String representing the desired passphrase
    # * iv: The optional +iv+ parameter is intended for testing use only. When
    # *not* supplied, Encryptor will use OpenSSL to generate a secure random
    # IV, which is what you want.
    def initialize(plaintext_data, key, iv=nil)
      @plaintext_data = plaintext_data
      @key = key
      @iv = iv && Base64.decode64(iv)
    end

    # Returns a wrapped and encrypted version of +plaintext_data+ suitable for
    # using as the value in an encrypted data bag item.
    def for_encrypted_item
      {
        "encrypted_data" => encrypted_data,
        "iv" => Base64.encode64(iv),
        "version" => 1,
        "cipher" => ALGORITHM
      }
    end

    # Generates or returns the IV.
    def iv
      # Generated IV comes from OpenSSL::Cipher::Cipher#random_iv
      # This gets generated when +openssl_encryptor+ gets created.
      openssl_encryptor if @iv.nil?
      @iv
    end

    # Generates (and memoizes) an OpenSSL::Cipher::Cipher object and configures
    # it for the specified iv and encryption key.
    def openssl_encryptor
      @openssl_encryptor ||= begin
        encryptor = OpenSSL::Cipher::Cipher.new(ALGORITHM)
        encryptor.encrypt
        @iv ||= encryptor.random_iv
        encryptor.iv = @iv
        encryptor.key = Digest::SHA256.digest(key)
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
      Yajl::Encoder.encode(:json_wrapper => plaintext_data)
    end
  end

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
      case format_version_of(encrypted_value)
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

    class Version1Decryptor

      attr_reader :encrypted_data
      attr_reader :key

      def initialize(encrypted_data, key)
        @encrypted_data = encrypted_data
        @key = key
      end

      def for_decrypted_item
        Yajl::Parser.parse(decrypted_data)["json_wrapper"]
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
  end

  def initialize(enc_hash, secret)
    @enc_hash = enc_hash
    @secret = secret
  end

  def [](key)
    value = @enc_hash[key]
    if key == "id" || value.nil?
      value
    else
      Decryptor.for(value, @secret).for_decrypted_item
    end
  end

  def []=(key, value)
    raise ArgumentError, "assignment not supported for #{self.class}"
  end

  def to_hash
    @enc_hash.keys.inject({}) { |hash, key| hash[key] = self[key]; hash }
  end

  def self.encrypt_data_bag_item(plain_hash, secret)
    plain_hash.inject({}) do |h, (key, val)|
      h[key] = if key != "id"
                 Encryptor.new(val, secret).for_encrypted_item
               else
                 val
               end
      h
    end
  end

  def self.load(data_bag, name, secret = nil)
    raw_hash = Chef::DataBagItem.load(data_bag, name)
    secret = secret || self.load_secret
    self.new(raw_hash, secret)
  end

  def self.load_secret(path=nil)
    path = path || Chef::Config[:encrypted_data_bag_secret] || DEFAULT_SECRET_FILE
    secret = case path
             when /^\w+:\/\//
               # We have a remote key
               begin
                 Kernel.open(path).read.strip
               rescue Errno::ECONNREFUSED
                 raise ArgumentError, "Remote key not available from '#{path}'"
               rescue OpenURI::HTTPError
                 raise ArgumentError, "Remote key not found at '#{path}'"
               end
             else
               if !File.exists?(path)
                 raise Errno::ENOENT, "file not found '#{path}'"
               end
               IO.read(path).strip
             end
    if secret.size < 1
      raise ArgumentError, "invalid zero length secret in '#{path}'"
    end
    secret
  end

end
