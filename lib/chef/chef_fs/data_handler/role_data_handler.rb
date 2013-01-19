require 'chef/chef_fs/data_handler/data_handler_base'
require 'chef/role'

class Chef
  module ChefFS
    module DataHandler
      class RoleDataHandler < DataHandlerBase
        def normalize(role, name)
          role['name'] ||= name
          role['description'] ||= ''
          role['json_class'] ||= 'Chef::Role'
          role['chef_type'] ||= 'role'
          role['default_attributes'] ||= {}
          role['override_attributes'] ||= {}
          role['run_list'] ||= []
          role['run_list'] = normalize_run_list(role['run_list'])
          role['env_run_lists'] ||= {}
          role['env_run_lists'].each_pair do |env, run_list|
            role['env_run_lists'][env] = normalize_run_list(run_list)
          end
          role
        end

        def chef_class
          Chef::Role
        end

        def to_ruby(object)
          to_ruby_keys(object, %w(name description default_attributes override_attributes run_list env_run_lists))
        end
      end
    end
  end
end
