#
# Author:: Tyler Ball (<tball@opscode.com>)
# Copyright:: Copyright (c) 2014 Opscode, Inc.
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

require 'mixlib/cli'
# TODO these were in a `deps` call before - okay that they aren't anymore?
require 'chef/config'
#require 'chef/data_bag'
require 'chef/encrypted_data_bag_item'

class Chef
  class Knife
    module DataBagSecretOptions
      include Mixlib::CLI

      option :secret,
             :short => "-s SECRET",
             :long  => "--secret ",
             :description => "The secret key to use to encrypt data bag item values",
             :proc => Proc.new { |s| Chef::Config[:knife][:secret] = s }

      option :secret_file,
             :long => "--secret-file SECRET_FILE",
             :description => "A file containing the secret key to use to encrypt data bag item values",
             :proc => Proc.new { |sf| Chef::Config[:knife][:secret_file] = sf }

      option :encrypt,
             :long => "--encrypt",
             :description => "Only use the secret configured in knife.rb when this is true",
             :boolean => true,
             :default => false

      ##
      # Determine if the user has specified an appropriate secret for encrypting data bag items.
      # @returns boolean
      def encryption_secret_provided?
        validate_secrets

        return true if config[:secret] || config[:secret_file]

        if config[:encrypt]
          unless has_secret? || has_secret_file?
            ui.fatal("No secret or secret_file specified in config, unable to encrypt item.")
            exit(1)
          else
            return true
          end
        end
        return false
      end

      def read_secret
        if config[:secret]
          config[:secret]
        elsif config[:secret_file]
          Chef::EncryptedDataBagItem.load_secret(config[:secret_file])
        elsif secret = knife_config[:secret] || Chef::Config[:secret]
          secret
        else
          secret_file = knife_config[:secret_file] || Chef::Config[:secret_file]
          Chef::EncryptedDataBagItem.load_secret(secret_file)
        end
      end

      def validate_secrets
        if config[:secret] && config[:secret_file]
          ui.fatal("Please specify only one of --secret, --secret-file")
          exit(1)
        end

        # TODO is there validation on the knife.rb schema?  If so, this validation should go there
        if has_secret? && has_secret_file?
          ui.fatal("Please specify only one of 'secret' or 'secret_file' in your config")
          exit(1)
        end
      end

      def has_secret?
        knife_config[:secret] || Chef::Config[:secret]
      end

      def has_secret_file?
        knife_config[:secret_file] || Chef::Config[:secret_file]
      end

      # TODO duplicated from data_query.rb
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

      def knife_config
        Chef::Config.key?(:knife) ? Chef::Config[:knife] : {}
      end

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
end
