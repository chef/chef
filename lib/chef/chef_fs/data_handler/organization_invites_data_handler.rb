require "chef/chef_fs/data_handler/data_handler_base"

class Chef
  module ChefFS
    module DataHandler
      class OrganizationInvitesDataHandler < DataHandlerBase
        def normalize(invites, entry)
          invites.map { |invite| invite.is_a?(Hash) ? invite["username"] : invite }.sort.uniq
        end

        def minimize(invites, entry)
          invites
        end
      end
    end
  end
end
