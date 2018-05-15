require "chef/chef_fs/data_handler/data_handler_base"

class Chef
  module ChefFS
    module DataHandler
      class OrganizationDataHandler < DataHandlerBase
        def normalize(organization, entry)
          result = normalize_hash(organization, {
            "name" => entry.org,
            "full_name" => entry.org,
            "org_type" => "Business",
            "clientname" => "#{entry.org}-validator",
            "billing_plan" => "platform-free",
          })
          result
        end

        def preserve_key?(key)
          key == "name"
        end

        # Verify that the JSON hash for this type has a key that matches its name.
        #
        # @param object [Object] JSON hash of the object
        # @param entry [Chef::ChefFS::FileSystem::BaseFSObject] filesystem object we are verifying
        # @yield  [s] callback to handle errors
        # @yieldparam [s<string>] error message
        def verify_integrity(object, entry)
          if entry.org != object["name"]
            yield("Name must be '#{entry.org}' (is '#{object['name']}')")
          end
        end
      end
    end
  end
end
