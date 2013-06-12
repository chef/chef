require 'chef/chef_fs/data_handler/data_handler_base'

class Chef
  module ChefFS
    module DataHandler
      class UserDataHandler < DataHandlerBase
        def normalize(user, entry)
          normalize_hash(user, {
            'name' => remove_dot_json(entry.name),
            'admin' => false,
            'json_class' => 'Chef::WebUIUser',
            'chef_type' => 'webui_user',
            'salt' => nil,
            'password' => nil,
            'openid' => nil
          })
        end

        def preserve_key(key)
          return key == 'name'
        end

        # There is no chef_class for users, nor does to_ruby work.
      end
    end
  end
end
