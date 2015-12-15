require 'chef/chef_fs/data_handler/data_handler_base'

class Chef
  module ChefFS
    module DataHandler
      class PolicyDataHandler < DataHandlerBase
        def name_and_revision(name)
          # foo-1.0.0 = foo, 1.0.0
          name = remove_dot_json(name)
          if name =~ /^(.*)-([^-]*)$/
            name, revision_id = $1, $2
          end
          revision_id ||= '0.0.0'
          [ name, revision_id ]
        end

        def normalize(policy, entry)
          # foo-1.0.0 = foo, 1.0.0
          name, revision_id = name_and_revision(entry.name)
          defaults = {
            'name' => name,
            'revision_id' => revision_id,
            'run_list' => [],
            'cookbook_locks' => {}
          }
          normalize_hash(policy, defaults)
        end

        def verify_integrity(object_data, entry, &on_error)
          name, revision = name_and_revision(entry.name)
          if object_data['name'] != name
            on_error.call("Object name '#{object_data['name']}' doesn't match entry '#{entry.name}'.")
          end

          if object_data['revision_id'] != revision
            on_error.call("Object revision ID '#{object_data['revision']}' doesn't match entry '#{entry.name}'.")
          end
        end
      end
    end
  end
end
