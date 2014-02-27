require 'chef/chef_fs/data_handler/data_handler_base'
require 'chef/environment'

class Chef
  module ChefFS
    module DataHandler
      class EnvironmentDataHandler < DataHandlerBase
        def normalize(environment, entry)
          normalize_hash(environment, {
            'name' => remove_dot_json(entry.name),
            'description' => '',
            'cookbook_versions' => {},
            'default_attributes' => {},
            'override_attributes' => {},
            'json_class' => 'Chef::Environment',
            'chef_type' => 'environment'
          })
        end

        def preserve_key(key)
          return key == 'name'
        end

        def chef_class
          Chef::Environment
        end

        def to_ruby(object)
          result = to_ruby_keys(object, %w(name description default_attributes override_attributes))
          if object['cookbook_versions']
            object['cookbook_versions'].each_pair do |name, version|
              result << "cookbook #{name.inspect}, #{version.inspect}"
            end
          end
          result
        end
      end
    end
  end
end
