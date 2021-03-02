#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Seth Falcon (<seth@chef.io>)
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

require_relative "../knife"
require_relative "data_bag_secret_options"

class Chef
  class Knife
    class DataBagShow < Knife
      include DataBagSecretOptions

      deps do
        require "chef/data_bag" unless defined?(Chef::DataBag)
        require "chef/encrypted_data_bag_item" unless defined?(Chef::EncryptedDataBagItem)
      end

      banner "knife data bag show BAG [ITEM] (options)"
      category "data bag"

      def run
        display = case @name_args.length
                  when 2 # Bag and Item names provided
                    secret = encryption_secret_provided_ignore_encrypt_flag? ? read_secret : nil
                    raw_data = Chef::DataBagItem.load(@name_args[0], @name_args[1]).raw_data
                    encrypted = encrypted?(raw_data)

                    if encrypted && secret
                      # Users do not need to pass --encrypt to read data, we simply try to use the provided secret
                      ui.info("Encrypted data bag detected, decrypting with provided secret.")
                      raw = Chef::EncryptedDataBagItem.load(@name_args[0],
                        @name_args[1],
                        secret)
                      format_for_display(raw.to_h)
                    elsif encrypted && !secret
                      ui.warn("Encrypted data bag detected, but no secret provided for decoding. Displaying encrypted data.")
                      format_for_display(raw_data)
                    else
                      ui.warn("Unencrypted data bag detected, ignoring any provided secret options.") if secret
                      format_for_display(raw_data)
                    end

                  when 1 # Only Bag name provided
                    format_list_for_display(Chef::DataBag.load(@name_args[0]))
                  else
                    stdout.puts opt_parser
                    exit(1)
                  end
        output(display)
      end

    end
  end
end
