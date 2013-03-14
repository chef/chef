require 'chef/chef_fs/data_handler/data_handler_base'

class Chef
  module ChefFS
    module DataHandler
      class AclDataHandler < DataHandlerBase
        def normalize(node, entry)
          # Normalize the order of the keys for easier reading
          result = super(node, {
            'create' => {},
            'read' => {},
            'update' => {},
            'delete' => {},
            'grant' => {}
            })
          result.keys.each do |key|
            result[key] = super(result[key], { 'actors' => [], 'groups' => [] })
          end
          result
        end
      end
    end
  end
end
