require 'chef/chef_fs/data_handler/data_handler_base'

class Chef
  module ChefFS
    module DataHandler
      class UserDataHandler < DataHandlerBase
        def self.normalize(user, name)
          user['name'] ||= name
          user['admin'] ||= false
          user['public_key'] ||= PUBLIC_KEY
          user
        end

        # There is no chef_class for users, nor does to_ruby work.
      end
    end
  end
end
