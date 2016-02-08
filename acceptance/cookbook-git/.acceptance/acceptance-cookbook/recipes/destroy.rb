# Run the test on the current platform
kitchen "destroy" do
  kitchen_dir "#{CookbookGit.test_run_path}/#{CookbookGit.test_cookbook_name}"
  env "BUNDLE_GEMFILE" => CookbookGit.acceptance_gemfile,
      "KITCHEN_GLOBAL_YAML" => ::File.join(CookbookGit.test_run_path, CookbookGit.test_cookbook_name, ".kitchen.yml"),
      "KITCHEN_YAML" => ::File.join(node["chef-acceptance"]["suite-dir"], ".kitchen.yml")
end
