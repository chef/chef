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
    class DataBagFromFile < Knife
      include DataBagSecretOptions

      deps do
        require "chef-config/path_helper" unless defined?(ChefConfig::PathHelper)
        require "chef/data_bag" unless defined?(Chef::DataBag)
        require "chef/data_bag_item" unless defined?(Chef::DataBagItem)
        require "chef/encrypted_data_bag_item" unless defined?(Chef::EncryptedDataBagItem)
        require_relative "core/object_loader"
      end

      banner "knife data bag from file BAG FILE|FOLDER [FILE|FOLDER..] (options)"
      category "data bag"

      option :all,
        short: "-a",
        long: "--all",
        description: "Upload all data bags or all items for specified data bags."

      def loader
        @loader ||= Knife::Core::ObjectLoader.new(Chef::DataBagItem, ui)
      end

      def run
        if config[:all] == true
          load_all_data_bags(@name_args)
        else
          if @name_args.size < 2
            ui.msg(opt_parser)
            exit(1)
          end
          @data_bag = @name_args.shift
          load_data_bag_items(@data_bag, @name_args)
        end
      end

      private

      def data_bags_path
        @data_bag_path ||= "data_bags"
      end

      def find_all_data_bags
        loader.find_all_object_dirs("./#{data_bags_path}")
      end

      def find_all_data_bag_items(data_bag)
        loader.find_all_objects("./#{data_bags_path}/#{data_bag}")
      end

      def load_all_data_bags(args)
        data_bags = args.empty? ? find_all_data_bags : [args.shift]
        data_bags.each do |data_bag|
          load_data_bag_items(data_bag)
        end
      end

      def load_data_bag_items(data_bag, items = nil)
        items ||= find_all_data_bag_items(data_bag)
        item_paths = normalize_item_paths(items)
        item_paths.each do |item_path|
          item = loader.load_from((data_bags_path).to_s, data_bag, item_path)
          item = if encryption_secret_provided?
                   Chef::EncryptedDataBagItem.encrypt_data_bag_item(item, read_secret)
                 else
                   item
                 end
          dbag = Chef::DataBagItem.new
          dbag.data_bag(data_bag)
          dbag.raw_data = item
          dbag.save
          ui.info("Updated data_bag_item[#{dbag.data_bag}::#{dbag.id}]")
        end
      end

      def normalize_item_paths(args)
        paths = []
        args.each do |path|
          if File.directory?(path)
            paths.concat(Dir.glob(File.join(ChefConfig::PathHelper.escape_glob_dir(path), "*.json")))
          else
            paths << path
          end
        end
        paths
      end
    end
  end
end
