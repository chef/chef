#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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
    class DataBagFromFile < Knife

      deps do
        require 'chef/data_bag'
        require 'chef/data_bag_item'
        require 'chef/knife/core/object_loader'
        require 'chef/json_compat'
        require 'chef/encrypted_data_bag_item'
      end

      banner "knife data bag from file BAG FILE (options)"
      category "data bag"

      option :secret,
      :short => "-s SECRET",
      :long  => "--secret ",
      :description => "The secret key to use to encrypt data bag item values",
      :proc  => Proc.new { |key| Chef::Config[:knife][:secret] = key }

      option :secret_file,
      :long => "--secret-file SECRET_FILE",
      :description => "A file containing the secret key to use to encrypt data bag item values",
      :proc => Proc.new { |key| Chef::Config[:knife][:secret_file] = key }

      def read_secret
        if Chef::Config[:knife][:secret]
          Chef::Config[:knife][:secret]
        else
          Chef::EncryptedDataBagItem.load_secret(Chef::Config[:knife][:secret_file])
        end
      end

      def use_encryption
        if Chef::Config[:knife][:secret] && Chef::Config[:knife][:secret_file]
          stdout.puts "please specify only one of --secret, --secret-file"
          exit(1)
        end
        Chef::Config[:knife][:secret] || Chef::Config[:knife][:secret_file]
      end

      def loader
        @loader ||= Knife::Core::ObjectLoader.new(DataBagItem, ui)
      end

      def run
        if @name_args.size != 2
          stdout.puts opt_parser
          exit(1)
        end
        @data_bag, @item_path = @name_args[0], @name_args[1]
        item = loader.load_from("data_bags", @data_bag, @item_path)
        item = if use_encryption
                 secret = read_secret
                 Chef::EncryptedDataBagItem.encrypt_data_bag_item(item, secret)
               else
                 item
               end
        dbag = Chef::DataBagItem.new
        dbag.data_bag(@name_args[0])
        dbag.raw_data = item
        dbag.save
        ui.info("Updated data_bag_item[#{dbag.data_bag}::#{dbag.id}]")
      end
    end
  end
end




