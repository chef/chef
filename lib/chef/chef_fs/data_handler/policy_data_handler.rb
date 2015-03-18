require 'chef/chef_fs/data_handler/data_handler_base'

class Chef
  module ChefFS
    module DataHandler
      class PolicyDataHandler < DataHandlerBase

        def normalize(policy, entry)
          policy
        end
      end
    end
  end
end

