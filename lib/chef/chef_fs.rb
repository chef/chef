require 'chef/chef_fs/file_system/chef_server_root_dir'
require 'chef/config'
require 'chef/rest'

class Chef
  module ChefFS
    def self.windows?
      false
    end
  end
end
