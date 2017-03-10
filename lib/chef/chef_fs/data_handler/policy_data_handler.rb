require "chef/chef_fs/data_handler/data_handler_base"

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
          revision_id ||= "0.0.0"
          [ name, revision_id ]
        end

        def normalize(policy, entry)
          # foo-1.0.0 = foo, 1.0.0
          name, revision_id = name_and_revision(entry.name)
          defaults = {
            "name" => name,
            "revision_id" => revision_id,
            "run_list" => [],
            "cookbook_locks" => {},
          }
          normalize_hash(policy, defaults)
        end

        # Verify that the JSON hash for this type has a key that matches its name.
        #
        # @param object [Object] JSON hash of the object
        # @param entry [Chef::ChefFS::FileSystem::BaseFSObject] filesystem object we are verifying
        # @yield  [s] callback to handle errors
        # @yieldparam [s<string>] error message
        def verify_integrity(object_data, entry)
          name, revision = name_and_revision(entry.name)
          if object_data["name"] != name
            yield("Object name '#{object_data['name']}' doesn't match entry '#{name}'.")
          end

          if object_data["revision_id"] != revision
            yield("Object revision ID '#{object_data['revision_id']}' doesn't match entry '#{revision}'.")
          end
        end
      end
    end
  end
end
