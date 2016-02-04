class Kitchen < Chef::Resource
  resource_name :kitchen

  property :command, String, name_property: true
  property :driver, %w(ec2 vagrant), coerce: proc { |v| v.to_s }, default: lazy { ENV["KITCHEN_DRIVER"] || :ec2 }
  property :instances, String, default: lazy { ENV["KITCHEN_INSTANCES"] }
  property :kitchen_dir, String, default: Chef.node['chef-acceptance']['suite-dir']
  property :chef_product, String, default: lazy { ENV["KITCHEN_CHEF_PRODUCT"] || ENV["PROJECT_NAME"] || "chef" }
  property :chef_channel, String, default: lazy { ENV["KITCHEN_CHEF_CHANNEL"] || ((ENV["KITCHEN_CHEF_VERSION"] || ENV["OMNIBUS_BUILD_VERSION"]) ? "unstable" : "current") }
  property :chef_version, String, default: lazy { ENV["KITCHEN_CHEF_VERSION"] || ENV["OMNIBUS_BUILD_VERSION"] || "latest" }
  property :artifactory_username, String, default: lazy { ENV["ARTIFACTORY_USERNAME"] }
  property :artifactory_password, String, default: lazy { ENV["ARTIFACTORY_PASSWORD"] }
  property :env, Hash, default: {}

  action :run do
    execute "bundle exec kitchen #{command}#{instances ? " #{instances}" : ""}" do
      cwd kitchen_dir
      env({
        "KITCHEN_DRIVER" => driver,
        "KITCHEN_INSTANCES" => instances,
        "KITCHEN_LOCAL_YAML" => ::File.join(Chef.node["chef-acceptance"]["suite-dir"], "../shared/.kitchen.#{driver}.yml"),
        "KITCHEN_CHEF_PRODUCT" => chef_product,
        "KITCHEN_CHEF_CHANNEL" => chef_channel,
        "KITCHEN_CHEF_VERSION" => chef_version,
        "ARTIFACTORY_USERNAME" => artifactory_username,
        "ARTIFACTORY_PASSWORD" => artifactory_password
      }.merge(new_resource.env))
    end
  end
end
