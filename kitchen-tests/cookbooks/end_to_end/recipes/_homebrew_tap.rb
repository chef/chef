homebrew_tap "chef/chef"

homebrew_tap "chef/chef" do
  action :untap
end

homebrew_tap("microsoft/git") do
  action [:tap]
  default_guard_interpreter :default
  declared_type :homebrew_tap
  cookbook_name "aces"
  recipe_name "git_prep"
  homebrew_path "/usr/local/bin/brew"
  tap_name "microsoft/git"
end
