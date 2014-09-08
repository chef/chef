#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright (c) 2009-2010 Opscode, Inc.
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

require 'chef/knife'

class Chef
  class Knife
    class DataBagEdit < Knife
      include DataBagSecretOptions

      deps do
        require 'chef/data_bag_item'
        require 'chef/encrypted_data_bag_item'
      end

      banner "knife data bag edit BAG ITEM (options)"
      category "data bag"

      def load_item(bag, item_name)
        item = Chef::DataBagItem.load(bag, item_name)
        if encrypted?(item.raw_data)
          if encryption_secret_provided?
            Chef::EncryptedDataBagItem.new(item, read_secret).to_hash
          else
            ui.fatal("You cannot edit an encrypted data bag without providing the secret.")
            exit(1)
          end
        else
          item
        end
      end

      def edit_item(item)
        output = edit_data(item)
        if encryption_secret_provided?
          ui.info("Encrypting data bag using provided secret.")
          Chef::EncryptedDataBagItem.encrypt_data_bag_item(output, read_secret)
        else
          ui.info("Saving data bag unencrypted.  To encrypt it, provide an appropriate secret.")
          output
        end
      end

      def run
        if @name_args.length != 2
          stdout.puts "You must supply the data bag and an item to edit!"
          stdout.puts opt_parser
          exit 1
        end
        item = load_item(@name_args[0], @name_args[1])
        output = edit_item(item)
        rest.put_rest("data/#{@name_args[0]}/#{@name_args[1]}", output)
        stdout.puts("Saved data_bag_item[#{@name_args[1]}]")
        # TODO this is trying to read :print_after from the CLI, not the knife.rb
        ui.output(output) if config[:print_after]
      end
    end
  end
end



