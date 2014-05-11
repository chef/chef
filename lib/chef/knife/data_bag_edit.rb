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

      deps do
        require 'chef/data_bag_item'
        require 'chef/encrypted_data_bag_item'
      end

      banner "knife data bag edit BAG ITEM (options)"
      category "data bag"

      option :secret,
        :short => "-s SECRET",
        :long  => "--secret ",
        :description => "The secret key to use to encrypt data bag item values",
        :proc => Proc.new { |s| Chef::Config[:knife][:secret] = s }

      option :secret_file,
        :long => "--secret-file SECRET_FILE",
        :description => "A file containing the secret key to use to encrypt data bag item values",
        :proc => Proc.new { |sf| Chef::Config[:knife][:secret_file] = sf }

      option :local_file,
        :short => "-l",
        :long => "--local-file",
        :description => "Assume ITEM is a local file to read from"

      def read_secret
        if config[:secret]
          config[:secret]
        else
          Chef::EncryptedDataBagItem.load_secret(config[:secret_file])
        end
      end

      def use_encryption
        if config[:secret] && config[:secret_file]
          stdout.puts "please specify only one of --secret, --secret-file"
          exit(1)
        end
        config[:secret] || config[:secret_file]
      end

      def load_item(bag, item_name)
        item = Chef::DataBagItem.load(bag, item_name)
        if use_encryption
          Chef::EncryptedDataBagItem.new(item, read_secret).to_hash
        else
          item
        end
      end

      def local_load_item(path)
        raw_item = JSON.parse(IO.read(path))
        item = Chef::DataBagItem.from_hash(raw_item)
        item.data_bag(@name_args[0])
        if use_encryption
          Chef::EncryptedDataBagItem.new(item, read_secret).to_hash
        else
          item
        end
      end

      def edit_item(item)
        output = edit_data(item)
        if use_encryption
          Chef::EncryptedDataBagItem.encrypt_data_bag_item(output, read_secret)
        else
          output
        end
      end

      def local_edit(path)
        item = local_load_item(path)
        output = edit_item(item)
        File.write(path, output.to_json)
        stdout.puts("Saved data_bag_item #{path}")
        ui.output(output) if config[:print_after]
      end

      def run
        if @name_args.length != 2
          stdout.puts "You must supply the data bag and an item to edit!"
          stdout.puts opt_parser
          exit 1
        end

        if config[:local_file]
          path = File.expand_path(@name_args[1])
          unless File.exists?(path)
            stdout.puts "#{path} not found"
            stdout.puts opt_parser
            exit 1
          end
          return local_edit(path)
        end

        item = load_item(@name_args[0], @name_args[1])
        output = edit_item(item)
        rest.put_rest("data/#{@name_args[0]}/#{@name_args[1]}", output)
        stdout.puts("Saved data_bag_item[#{@name_args[1]}]")
        ui.output(output) if config[:print_after]
      end
    end
  end
end
