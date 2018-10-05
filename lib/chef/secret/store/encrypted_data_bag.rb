class Chef
  class Secret
    class Store
      class EncryptedDataBag < Chef::Secret::Store::DataBag
        require "chef/encrypted_data_bag_item"

        attr_accessor :data_bag_token

        def validate!
					super
          raise "'data_bag_token' is a required configuration for #{self}" unless @data_bag_token
        end

        def read(key)
          validate!
          Chef::EncryptedDataBagItem.load(@data_bag_name, @data_bag_item, @data_bag_token).to_hash[key.to_s]
        end

      end
    end
  end
end
