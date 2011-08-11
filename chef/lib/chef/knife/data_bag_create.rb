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
    class DataBagCreate < Knife

      deps do
        require 'chef/data_bag'
        require 'chef/encrypted_data_bag_item'
      end

      banner "knife data bag create BAG [ITEM] (options)"
      category "data bag"

      option :secret,
      :short => "-s SECRET",
      :long  => "--secret ",
      :description => "The secret key to use to encrypt data bag item values"

      option :secret_file,
      :long => "--secret-file SECRET_FILE",
      :description => "A file containing the secret key to use to encrypt data bag item values"

      def read_secret
        if config[:secret]
          config[:secret]
        else
          Chef::EncryptedDataBagItem.load_secret(config[:secret_file])
        end
      end

      def use_encryption
        if config[:secret] && config[:secret_file]
          ui.fatal("please specify only one of --secret, --secret-file")
          exit(1)
        end
        config[:secret] || config[:secret_file]
      end

      def run
        @data_bag_name, @data_bag_item_name = @name_args

        if @data_bag_name.nil?
          show_usage
          ui.fatal("You must specify a data bag name")
          exit 1
        end

        # create the data bag
        begin
          rest.post_rest("data", { "name" => @data_bag_name })
          ui.info("Created data_bag[#{@data_bag_name}]")
        rescue Net::HTTPServerException => e
          raise unless e.to_s =~ /^409/
          ui.info("Data bag #{@data_bag_name} already exists")
        end

        # if an item is specified, create it, as well
        if @data_bag_item_name
          create_object({ "id" => @data_bag_item_name }, "data_bag_item[#{@data_bag_item_name}]") do |output|
            item = Chef::DataBagItem.from_hash(
                     if use_encryption
                       Chef::EncryptedDataBagItem.encrypt_data_bag_item(output, read_secret)
                     else
                       output
                     end)
            item.data_bag(@data_bag_name)
            rest.post_rest("data/#{@data_bag_name}", item)
          end
        end
      end
    end
  end
end
