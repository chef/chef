require 'chef/chef_fs/data_handler/data_handler_base'
require 'chef/node'

class Chef
  module ChefFS
    module DataHandler
      class NodeDataHandler < DataHandlerBase
        def normalize(node, name)
          node['name'] ||= name
          node['json_class'] ||= 'Chef::Node'
          node['chef_type'] ||= 'node'
          node['chef_environment'] ||= '_default'
          node['override'] ||= {}
          node['normal'] ||= {}
          node['default'] ||= {}
          node['automatic'] ||= {}
          node['run_list'] ||= []
          node['run_list'] = normalize_run_list(node['run_list'])
          node
        end

        def chef_class
          Chef::Node
        end

        # Nodes do not support .rb files
      end
    end
  end
end
