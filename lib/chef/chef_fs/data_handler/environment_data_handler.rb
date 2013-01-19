require 'chef/chef_fs/data_handler/data_handler_base'
require 'chef/environment'

class Chef
  module ChefFS
    module DataHandler
      class EnvironmentDataHandler < DataHandlerBase
        def normalize(environment, name)
          environment['name'] ||= name
          environment['description'] ||= ''
          environment['cookbook_versions'] ||= {}
          environment['json_class'] ||= "Chef::Environment"
          environment['chef_type'] ||= "environment"
          environment['default_attributes'] ||= {}
          environment['override_attributes'] ||= {}
          environment
        end

        def chef_class
          Chef::Environment
        end

        def to_ruby(object)
          result = to_ruby_keys(object, %w(name description default_attributes override_attributes))
          if object['cookbook_versions']
            object['cookbook_versions'].each_pair do |name, version|
              result << "cookbook #{name.inspect}, #{version.inspect}"
            end
          end
          result
        end
      end
    end
  end
end
