#
# Author:: Salim Afiune (<afiune@getchef.com>)
# Copyright:: Copyright (c) 2014, Chef Software, Inc. <legal@getchef.com>
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
    class DataBagDownload < Knife

      deps do
        require 'chef/data_bag'
        require 'chef/encrypted_data_bag_item'
      end

      banner "knife data bag download BAG (options)"
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

      option :data_bag_path,
        :short => "-p DATA_BAG_PATH",
        :long => "--data-bag-path DATA_BAG_PATH",
        :description => "Path where the data bag will be downloaded",
        :proc => Proc.new { |dbp| Chef::Config[:knife][:data_bag_path] = dbp }

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
        @data_bag_name = @name_args[0]

        if @data_bag_name.nil?
          show_usage
          ui.fatal("You must specify a data bag name")
          exit 1
        elsif @name_args.length > 1
          show_usage
          ui.fatal("Please specify only one argument")
          exit 1
        end

        FileUtils.mkdir_p(File.join(Chef::Config[:data_bag_path], @data_bag_name))

        Chef::DataBag.load(@data_bag_name).each do |item, api|
          ui.info("Downloading #{@data_bag_name}/#{item}")
          File.open(File.join(Chef::Config[:data_bag_path], @data_bag_name, "#{item}.json"), "w") do |f|
            if use_encryption
              raw = Chef::EncryptedDataBagItem.load(@data_bag_name,
                                                    item,
                                                    read_secret)
              f.write(JSON.pretty_generate(raw.to_hash))
            else
              f.write(JSON.pretty_generate(Chef::DataBagItem.load(@data_bag_name, item).raw_data))
            end
          end
        end

      end
    end
  end
end
