class CookbookKitchen < KitchenAcceptance::Kitchen
  resource_name :cookbook_kitchen

  property :command, default: lazy { name.split(" ")[0] }
  property :test_cookbook, default: lazy { name.split(" ")[1] }
  property :kitchen_dir, default: lazy { ::File.join(Chef.node["chef-acceptance"]["suite-dir"], "test_run", test_cookbook) }
  property :repository, default: lazy { "chef-cookbooks/#{test_cookbook}" },
    coerce: proc { |v|
      # chef-cookbooks/runit -> https://github.com/chef-cookbooks/runit.git
      if !v.include?(':')
        "https://github.com/#{v}.git"
      else
        v
      end
    }
  property :branch, default: "master"
  property :env, default: lazy {
    {
      "BUNDLE_GEMFILE" => ::File.expand_path("../Gemfile", Chef.node["chef-acceptance"]["suite-dir"]),
      "KITCHEN_GLOBAL_YAML" => ::File.join(kitchen_dir, ".kitchen.yml"),
      "KITCHEN_YAML" => ::File.join(node["chef-acceptance"]["suite-dir"], ".kitchen.yml")
    }
  }

  action :run do
    if command == "converge"
      # Ensure the parent directory exists
      directory ::File.expand_path("..", kitchen_dir)

      # Grab the cookbook
      # TODO Grab the source URL from supermarket
      # TODO get git to include its kitchen tests in the cookbook.
      git kitchen_dir do
        repository new_resource.repository
        branch new_resource.branch
      end
    end

    super()
  end
end
