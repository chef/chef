# Run tests on the current platform
execute "bundle exec kitchen verify #{ENV['KITCHEN_INSTANCES']} -c" do
  cwd "#{CookbookGit.test_run_path}/#{CookbookGit.test_cookbook_name}"
  env "BUNDLE_GEMFILE" => CookbookGit.acceptance_gemfile
end
