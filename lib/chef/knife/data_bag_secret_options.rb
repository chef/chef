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
require 'chef/config'
require 'chef/encrypted_data_bag_item/check_encrypted'

class Chef
  class Knife
    module DataBagSecretOptions
      include Mixlib::CLI
      include Chef::EncryptedDataBagItem::CheckEncrypted

      def self.included(base)
        base.option :secret,
               :short => "-s SECRET",
               :long  => "--secret ",
               :description => "The secret key to use to encrypt data bag item values.  Can also be defaulted in your config with the key 'secret'",
               :proc => Proc.new { |s| Chef::Config[:knife][:secret] = s }

        base.option :secret_file,
               :long => "--secret-file SECRET_FILE",
               :description => "A file containing the secret key to use to encrypt data bag item values.  Can also be defaulted in your config with the key 'secret_file'",
               :proc => Proc.new { |sf| Chef::Config[:knife][:secret_file] = sf }

        base.option :encrypt,
               :long => "--encrypt",
               :description => "If 'secret' or 'secret_file' is present in your config, then encrypt data bags using it",
               :boolean => true,
               :default => false
      end

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
        # Moving the non 'compile-time' requires into here to speed up knife command loading
        # IE, if we are not running 'knife data bag *' we don't need to load 'chef/encrypted_data_bag_item'
        require 'chef/encrypted_data_bag_item'

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

      private

      def knife_config
        Chef::Config.key?(:knife) ? Chef::Config[:knife] : {}
      end

    end
  end
end
