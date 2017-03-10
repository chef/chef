require "chef/chef_fs/file_system/repository/file_system_entry"

module Chef::ChefFS::FileSystem::Repository
  Chef.deprecated :internal_api, "Chef::ChefFS::FileSystem::Repository::ChefRepositoryFileSystemEntry is deprecated. Please use FileSystemEntry directly"
  ChefRepositoryFileSystemEntry = FileSystemEntry
end
