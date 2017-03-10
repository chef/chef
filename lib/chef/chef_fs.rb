require "chef/platform"

#
# ChefFS was designed to be a near-1:1 translation between Chef server endpoints
# and local data, so that it could be used for:
#
# 1. User editing, diffing and viewing of server content locally
# 2. knife download, upload and diff (supporting the above scenario)
# 3. chef-client -z (serving user repository directly)
#
# This is the translation between chef-zero data stores (which correspond
# closely to server endpoints) and the ChefFS repository format.
#
# |-----------------------------------|-----------------------------------|
# | chef-zero DataStore               | ChefFS (repository)               |
# |-----------------------------------|-----------------------------------|
# | <root>                            | org.json                          |
# | association_requests/NAME         | invitations.json                  |
# | clients/NAME                      | clients/NAME.json                 |
# | cookbooks/NAME/VERSION            | cookbooks/NAME/metadata.rb        |
# | containers/NAME                   | containers/NAME.json              |
# | data/BAG/ITEM                     | data_bags/BAG/ITEM.json           |
# | environments/NAME                 | environments/NAME.json            |
# | groups/NAME                       | groups/NAME.json                  |
# | nodes/NAME                        | nodes/NAME.json                   |
# | policies/NAME/REVISION            | policies/NAME-REVISION.json       |
# | policy_groups/NAME/policies/PNAME | policy_groups/NAME.json           |
# | roles/NAME                        | roles/NAME.json                   |
# | sandboxes/ID                      | <not stored on disk, just memory> |
# | users/NAME                        | members.json                      |
# | file_store/COOKBOOK/VERSION/PATH  | cookbooks/COOKBOOK/PATH           |
# | **/_acl                           | acls/**.json                      |
# |-----------------------------------|-----------------------------------|
#
#
# ## The Code
#
# There are two main entry points to ChefFS:
#
# - ChefServerRootDir represents the chef server (under an org) and surfaces a
#   filesystem-like interface (FSBaseObject / FSBaseDir) that maps the REST API
#   to the same format as you would have on disk.
# - ChefRepositoryFileSystemRootDir represents the local repository where you
#   put your cookbooks, roles, policies, etc.
#
# Because these two map to a common directory structure, diff, upload, download,
# and other filesystem operations, can easily be done in a generic manner.
#
# These are instantiated by Chef::ChefFS::Config's `chef_fs` and `local_fs`
# methods.
#

class Chef
  module ChefFS
    def self.windows?
      Chef::Platform.windows?
    end
  end
end
