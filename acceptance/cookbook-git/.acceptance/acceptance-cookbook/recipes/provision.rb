# Grab the cookbook
directory CookbookGit.test_run_path
# TODO Grab the source URL from supermarket
# TODO get git to include its kitchen tests in the cookbook.
git "#{CookbookGit.test_run_path}/#{CookbookGit.test_cookbook_name}" do
  repository "https://github.com/jkeiser/#{CookbookGit.test_cookbook_name}.git"
  branch "jk/windows-fix"
end

# Run the test on the current platform
execute "bundle exec kitchen converge #{ENV['KITCHEN_INSTANCES']} -c" do
  cwd "#{CookbookGit.test_run_path}/#{CookbookGit.test_cookbook_name}"
  env "BUNDLE_GEMFILE" => CookbookGit.acceptance_gemfile
end
