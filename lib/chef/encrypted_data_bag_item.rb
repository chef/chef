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

require "chef/config"
require "chef/data_bag_item"
require "chef/encrypted_data_bag_item/decryptor"
require "chef/encrypted_data_bag_item/encryptor"
require "open-uri"

# An EncryptedDataBagItem represents a read-only data bag item where
# all values, except for the value associated with the id key, have
# been encrypted.
#
# EncryptedDataBagItem can be used in recipes to decrypt data bag item
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
  ALGORITHM = "aes-256-cbc"
  AEAD_ALGORITHM = "aes-256-gcm"

  #
  # === Synopsis
  #
  #   EncryptedDataBagItem.new(hash, secret)
  #
  # === Args
  #
  # +enc_hash+::
  #   The encrypted hash to be decrypted
  # +secret+::
  #   The raw secret key
  #
  # === Description
  #
  # Create a new encrypted data bag item for reading (decryption)
  #
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

  #
  # === Synopsis
  #
  #   EncryptedDataBagItem.load(data_bag, name, secret = nil)
  #
  # === Args
  #
  # +data_bag+::
  #   The name of the data bag to fetch
  # +name+::
  #   The name of the data bag item to fetch
  # +secret+::
  #   The raw secret key. If the +secret+ is nil, the value of the file at
  #   +Chef::Config[:encrypted_data_bag_secret]+ is loaded. See +load_secret+
  #   for more information.
  #
  # === Description
  #
  # Loads and decrypts the data bag item with the given name.
  #
  def self.load(data_bag, name, secret = nil)
    raw_hash = Chef::DataBagItem.load(data_bag, name)
    secret ||= self.load_secret
    self.new(raw_hash, secret)
  end

  def self.load_secret(path = nil)
    path ||= Chef::Config[:encrypted_data_bag_secret]
    if !path
      raise ArgumentError, "No secret specified and no secret found at #{Chef::Config.platform_specific_path('/etc/chef/encrypted_data_bag_secret')}"
    end
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
               if !File.exist?(path)
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
