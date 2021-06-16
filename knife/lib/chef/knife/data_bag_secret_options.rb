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

require "mixlib/cli" unless defined?(Mixlib::CLI)
require "chef/config" unless defined?(Chef::Config)
require "encrypted_data_bag_item/check_encrypted" unless defined?(Chef::EncryptedDataBagItem::CheckEncrypted)

class Chef
  class Knife
    module DataBagSecretOptions
      include Mixlib::CLI
      include Chef::EncryptedDataBagItem::CheckEncrypted

      # The config object is populated by knife#merge_configs with knife.rb `knife[:*]` config values, but they do
      # not overwrite the command line properties.  It does mean, however, that `knife[:secret]` and `--secret-file`
      # passed at the same time populate both `config[:secret]` and `config[:secret_file]`.  We cannot differentiate
      # the valid case (`knife[:secret]` in config file and `--secret-file` on CL) and the invalid case (`--secret`
      # and `--secret-file` on the CL) - thats why I'm storing the CL options in a different config key if they
      # are provided.

      def self.included(base)
        base.option :cl_secret,
          long: "--secret SECRET",
          description: "The secret key to use to encrypt data bag item values. Can also be defaulted in your config with the key 'secret'."

        base.option :cl_secret_file,
          long: "--secret-file SECRET_FILE",
          description: "A file containing the secret key to use to encrypt data bag item values. Can also be defaulted in your config with the key 'secret_file'."

        base.option :encrypt,
          long: "--encrypt",
          description: "If 'secret' or 'secret_file' is present in your config, then encrypt data bags using it.",
          boolean: true,
          default: false
      end

      def encryption_secret_provided?
        base_encryption_secret_provided?
      end

      def encryption_secret_provided_ignore_encrypt_flag?
        base_encryption_secret_provided?(false)
      end

      def read_secret
        # Moving the non 'compile-time' requires into here to speed up knife command loading
        # IE, if we are not running 'knife data bag *' we don't need to load 'chef/encrypted_data_bag_item'
        require "chef/encrypted_data_bag_item" unless defined?(Chef::EncryptedDataBagItem)

        if config[:cl_secret]
          config[:cl_secret]
        elsif config[:cl_secret_file]
          Chef::EncryptedDataBagItem.load_secret(config[:cl_secret_file])
        elsif secret = config[:secret]
          secret
        else
          secret_file = config[:secret_file]
          Chef::EncryptedDataBagItem.load_secret(secret_file)
        end
      end

      def validate_secrets
        if config[:cl_secret] && config[:cl_secret_file]
          ui.fatal("Please specify only one of --secret, --secret-file")
          exit(1)
        end

        if config[:secret] && config[:secret_file]
          ui.fatal("Please specify only one of 'secret' or 'secret_file' in your config file")
          exit(1)
        end
      end

      private

      ##
      # Determine if the user has specified an appropriate secret for encrypting data bag items.
      # @return boolean
      def base_encryption_secret_provided?(need_encrypt_flag = true)
        validate_secrets

        return true if config[:cl_secret] || config[:cl_secret_file]

        if need_encrypt_flag
          if config[:encrypt]
            unless config[:secret] || config[:secret_file]
              ui.fatal("No secret or secret_file specified in config, unable to encrypt item.")
              exit(1)
            end
            return true
          end
          return false
        elsif config[:secret] || config[:secret_file]
          # Certain situations (show and bootstrap) don't need a --encrypt flag to use the config file secret
          return true
        end
        false
      end

      def knife_config
        Chef.deprecated(:knife_bootstrap_apis, "The `knife_config` bootstrap helper has been deprecated, use the properly merged `config` helper instead")
        Chef::Config.key?(:knife) ? Chef::Config[:knife] : {}
      end

    end
  end
end
