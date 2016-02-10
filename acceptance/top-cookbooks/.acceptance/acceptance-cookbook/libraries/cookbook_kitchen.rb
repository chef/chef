class CookbookKitchen < KitchenAcceptance::Kitchen
  resource_name :cookbook_kitchen

  property :command, default: lazy { name.split(" ")[0] }
  property :kitchen_dir, default: lazy { ::File.join(repository_root, cookbook_relative_dir) }
  property :test_cookbook, String, default: lazy { name.split(" ")[1] }
  property :repository, String, default: lazy { "chef-cookbooks/#{test_cookbook}" },
    coerce: proc { |v|
      # chef-cookbooks/runit -> https://github.com/chef-cookbooks/runit.git
      if !v.include?(':')
        "https://github.com/#{v}.git"
      else
        v
      end
    }
  property :repository_root, String, default: lazy { ::File.join(Chef.node["chef-acceptance"]["suite-dir"], "test_run", test_cookbook) }
  property :branch, String, default: "master"
  property :cookbook_relative_dir, String, default: ""
  property :env, default: lazy {
    {
      "BUNDLE_GEMFILE" => ::File.expand_path("../Gemfile", Chef.node["chef-acceptance"]["suite-dir"]),
#      "KITCHEN_GLOBAL_YAML" => ::File.join(kitchen_dir, ".kitchen.yml"),
      "KITCHEN_YAML" => ::File.join(node["chef-acceptance"]["suite-dir"], ".kitchen.#{test_cookbook}.yml")
    }
  }

  action :run do
    # Ensure the parent directory exists
    directory ::File.expand_path("..", repository_root) do
      recursive true
    end

    # Grab the cookbook
    # TODO Grab the source URL from supermarket
    # TODO get git to include its kitchen tests in the cookbook.
    git repository_root do
      repository new_resource.repository
      branch new_resource.branch
    end

    super()
  end
end
