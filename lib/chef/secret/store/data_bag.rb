class Chef
  class Secret
    class Store
      class DataBag < Chef::Secret::Store
        require "chef/data_bag_item"

        attr_accessor :data_bag_name
        attr_accessor :data_bag_item

        def validate!
          raise "'data_bag_name' is a required configuration for #{self}" unless @data_bag_name
          raise "'data_bag_item' is a required configuration for #{self}" unless @data_bag_item
        end

        def read(key)
          validate!
          Chef::DataBagItem.load(@data_bag_name, @data_bag_item).to_hash[key.to_s]
        end
      end
    end
  end
end
