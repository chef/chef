require 'chef/chef_fs/data_handler/data_handler_base'
require 'chef/data_bag_item'

class Chef
  module ChefFS
    module DataHandler
      class DataBagItemDataHandler < DataHandlerBase
        def normalize(data_bag_item, data_bag_name, id)
          # If it's wrapped with raw_data, unwrap it.
          if data_bag_item['json_class'] == 'Chef::DataBagItem' && data_bag_item['raw_data']
            data_bag_item = data_bag_item['raw_data']
          end
          # chef_type and data_bag only come back from PUT and POST, but we'll
          # normalize them in in case someone is comparing with those results.
          data_bag_item['chef_type'] ||= 'data_bag_item'
          data_bag_item['data_bag'] ||= data_bag_name
          data_bag_item['id'] ||= id
          data_bag_item
        end

        def chef_class
          Chef::DataBagItem
        end

        # Data bags do not support .rb files (or if they do, it's undocumented)
      end
    end
  end
end
