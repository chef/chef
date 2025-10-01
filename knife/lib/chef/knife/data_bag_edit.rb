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
    class DataBagEdit < Knife
      include DataBagSecretOptions

      deps do
        require "chef/data_bag_item" unless defined?(Chef::DataBagItem)
        require "chef/encrypted_data_bag_item" unless defined?(Chef::EncryptedDataBagItem)
      end

      banner "knife data bag edit BAG ITEM (options)"
      category "data bag"

      def load_item(bag, item_name)
        item = Chef::DataBagItem.load(bag, item_name)
        if encrypted?(item.raw_data)
          if encryption_secret_provided_ignore_encrypt_flag?
            [Chef::EncryptedDataBagItem.new(item, read_secret).to_hash, true]
          else
            ui.fatal("You cannot edit an encrypted data bag without providing the secret.")
            exit(1)
          end
        else
          [item.raw_data, false]
        end
      end

      def run
        if @name_args.length != 2
          stdout.puts "You must supply the data bag and an item to edit"
          stdout.puts opt_parser
          exit 1
        end

        item, was_encrypted = load_item(@name_args[0], @name_args[1])
        edited_item = edit_hash(item)

        if was_encrypted || encryption_secret_provided?
          ui.info("Encrypting data bag using provided secret.")
          item_to_save = Chef::EncryptedDataBagItem.encrypt_data_bag_item(edited_item, read_secret)
        else
          ui.info("Saving data bag unencrypted. To encrypt it, provide an appropriate secret.")
          item_to_save = edited_item
        end

        rest.put("data/#{@name_args[0]}/#{@name_args[1]}", item_to_save)
        stdout.puts("Saved data_bag_item[#{@name_args[1]}]")
        ui.output(edited_item) if config[:print_after]
      end
    end
  end
end
