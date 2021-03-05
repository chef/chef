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
    class DataBagCreate < Knife
      include DataBagSecretOptions

      deps do
        require "chef/data_bag" unless defined?(Chef::DataBag)
        require "chef/encrypted_data_bag_item" unless defined?(Chef::EncryptedDataBagItem)
      end

      banner "knife data bag create BAG [ITEM] (options)"
      category "data bag"

      def run
        @data_bag_name, @data_bag_item_name = @name_args

        if @data_bag_name.nil?
          show_usage
          ui.fatal("You must specify a data bag name")
          exit 1
        end

        begin
          Chef::DataBag.validate_name!(@data_bag_name)
        rescue Chef::Exceptions::InvalidDataBagName => e
          ui.fatal(e.message)
          exit(1)
        end

        # Verify if the data bag exists
        begin
          rest.get("data/#{@data_bag_name}")
          ui.info("Data bag #{@data_bag_name} already exists")
        rescue Net::HTTPClientException => e
          raise unless /^404/.match?(e.to_s)

          # if it doesn't exists, try to create it
          rest.post("data", { "name" => @data_bag_name })
          ui.info("Created data_bag[#{@data_bag_name}]")
        end

        # if an item is specified, create it, as well
        if @data_bag_item_name
          create_object({ "id" => @data_bag_item_name }, "data_bag_item[#{@data_bag_item_name}]") do |output|
            item = Chef::DataBagItem.from_hash(
              if encryption_secret_provided?
                Chef::EncryptedDataBagItem.encrypt_data_bag_item(output, read_secret)
              else
                output
              end
            )
            item.data_bag(@data_bag_name)
            rest.post("data/#{@data_bag_name}", item)
          end
        end
      end
    end
  end
end
