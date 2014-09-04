require 'chef/chef_fs/data_handler/data_handler_base'

class Chef
  module ChefFS
    module DataHandler
      class OrganizationDataHandler < DataHandlerBase
        def normalize(organization, entry)
          result = normalize_hash(organization, {
            'name' => entry.org,
            'full_name' => entry.org,
            'org_type' => 'Business',
            'clientname' => "#{entry.org}-validator",
            'billing_plan' => 'platform-free',
          })
          result
        end

        def preserve_key?(key)
          return key == 'name'
        end

        def verify_integrity(object, entry, &on_error)
          if entry.org != object['name']
            on_error.call("Name must be '#{entry.org}' (is '#{object['name']}')")
          end
        end
      end
    end
  end
end
