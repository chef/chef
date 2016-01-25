# Run the test on the current platform
execute "bundle exec kitchen destroy #{ENV['KITCHEN_INSTANCES']}" do
  cwd "#{CookbookGit.test_run_path}/#{CookbookGit.test_cookbook_name}"
  env "BUNDLE_GEMFILE" => CookbookGit.acceptance_gemfile
end
