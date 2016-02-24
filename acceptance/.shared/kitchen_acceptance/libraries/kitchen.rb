module KitchenAcceptance
  class Kitchen < Chef::Resource
    resource_name :kitchen

    property :command, String, name_property: true
    property :driver, %w(ec2 vagrant), coerce: proc { |v| v.to_s }, default: lazy { ENV["KITCHEN_DRIVER"] || :ec2 }
    property :instances, String, default: lazy { ENV["KITCHEN_INSTANCES"] ? ENV["KITCHEN_INSTANCES"] : "" }
    property :kitchen_dir, String, default: Chef.node['chef-acceptance']['suite-dir']
    property :chef_product, String, default: lazy {
      ENV["KITCHEN_CHEF_PRODUCT"] || begin
        # Figure out if we're in chefdk or chef
        if ::File.exist?(::File.expand_path("../../chef-dk.gemspec", node['chef-acceptance']['suite-dir']))
          "chefdk"
        else
          "chef"
        end
      end
    }
    property :chef_channel, String, default: lazy {
      ENV["KITCHEN_CHEF_CHANNEL"] ||
      # Pick up current if we can't connect to artifactory
      (ENV["ARTIFACTORY_USERNAME"] ? "unstable" : "current")
    }
    property :chef_version, String, default: lazy {
      ENV["KITCHEN_CHEF_VERSION"] ||
      # If we're running the chef or chefdk projects in jenkins, pick up the project name.
      (ENV["PROJECT_NAME"] == chef_product ? ENV["OMNIBUS_BUILD_VERSION"] : nil) ||
      "latest"
    }
    property :artifactory_username, String, default: lazy { ENV["ARTIFACTORY_USERNAME"] ? ENV["ARTIFACTORY_USERNAME"] : "" }
    property :artifactory_password, String, default: lazy { ENV["ARTIFACTORY_PASSWORD"] ? ENV["ARTIFACTORY_PASSWORD"] : "" }
    property :env, Hash, default: {}
    property :kitchen_options, String, default: lazy { ENV["PROJECT_NAME"] ? "-c -l debug" : "-c" }

    action :run do
      execute "bundle exec kitchen #{command}#{instances ? " #{instances}" : ""}#{kitchen_options ? " #{kitchen_options}" : ""}" do
        cwd kitchen_dir
        env({
          "KITCHEN_DRIVER" => driver,
          "KITCHEN_INSTANCES" => instances,
          "KITCHEN_LOCAL_YAML" => ::File.expand_path("../../.kitchen.#{driver}.yml", __FILE__),
          "KITCHEN_CHEF_PRODUCT" => chef_product,
          "KITCHEN_CHEF_CHANNEL" => chef_channel,
          "KITCHEN_CHEF_VERSION" => chef_version,
          "ARTIFACTORY_USERNAME" => artifactory_username,
          "ARTIFACTORY_PASSWORD" => artifactory_password
        }.merge(new_resource.env))
      end
    end
  end
end
