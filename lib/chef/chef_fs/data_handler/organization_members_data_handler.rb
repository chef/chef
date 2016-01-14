require "chef/chef_fs/data_handler/data_handler_base"

class Chef
  module ChefFS
    module DataHandler
      class OrganizationMembersDataHandler < DataHandlerBase
        def normalize(members, entry)
          members.map { |member| member.is_a?(Hash) ? member["user"]["username"] : member }.sort.uniq
        end

        def minimize(members, entry)
          members
        end
      end
    end
  end
end
