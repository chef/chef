homebrew_tap "chef/chef"

homebrew_tap "chef/chef" do
  action :untap
end

homebrew_tap("microsoft/git") do
  action :tap
  # homebrew_path "/usr/local/bin/brew"
  tap_name "microsoft/git"
end
