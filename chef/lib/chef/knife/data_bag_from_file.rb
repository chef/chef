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
require 'chef/data_bag'
require 'chef/data_bag_item'
require 'chef/json_compat'
require 'chef/encrypted_data_bag_item'

class Chef
  class Knife
    class DataBagFromFile < Knife

      banner "knife data bag from file BAG FILE (options)"
      category "data bag"

      option :secret,
      :short => "-s SECRET",
      :long  => "--secret ",
      :description => "The secret key to use to encrypt data bag item values"

      option :secret_file,
      :long => "--secret_file SECRET_FILE",
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
          stdout.puts "please specify only one of --secret, --secret_file"
          exit(1)
        end
        config[:secret] || config[:secret_file]
      end

      def run
        if @name_args.size != 2
          stdout.puts opt_parser
          exit(1)
        end
        item = load_from_file(Chef::DataBagItem, @name_args[1], @name_args[0])
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
        Chef::Log.info("Updated data_bag_item[#{@name_args[1]}]")
      end
    end
  end
end




