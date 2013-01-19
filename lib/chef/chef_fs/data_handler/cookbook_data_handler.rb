require 'chef/chef_fs/data_handler/data_handler_base'
require 'chef/cookbook/metadata'

class Chef
  module ChefFS
    module DataHandler
      class CookbookDataHandler < DataHandlerBase
        def normalize(cookbook, name, version)
          cookbook['name'] ||= "#{name}-#{version}"
          cookbook['version'] ||= version
          cookbook['cookbook_name'] ||= name
          cookbook['json_class'] ||= 'Chef::CookbookVersion'
          cookbook['chef_type'] ||= 'cookbook_version'
          cookbook['frozen?'] ||= false
          cookbook['metadata'] ||= {}
          cookbook['metadata']['version'] ||= version
          cookbook['metadata']['name'] ||= name
          cookbook
        end

        def chef_class
          Chef::Cookbook::Metadata
        end

        # Not using this yet, so not sure if to_ruby will be useful.
      end
    end
  end
end
