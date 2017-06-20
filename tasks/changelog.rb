begin
  require "github_changelog_generator/task"
  require "mixlib/install"

  namespace :changelog do
    # Fetch the latest version from mixlib-install
    latest_stable_version = Mixlib::Install.available_versions("chef", "stable").select { |n| n.start_with? "12" }.last

    # Take the changelog from the latest stable release and put it into history.
    task :archive do
      changelog = Net::HTTP.get(URI("https://raw.githubusercontent.com/chef/chef/v#{latest_stable_version}/CHANGELOG.md")).chomp.split("\n")
      File.open("HISTORY.md", "w+") { |f| f.write(changelog[2..-4].join("\n")) }
    end

    # Run this to just update the changelog for the current release. This will
    # take what is in HISTORY and generate a changelog of PRs between the most
    # recent stable version and HEAD.
    GitHubChangelogGenerator::RakeTask.new :update do |config|
      config.future_release = "v#{Chef::VERSION}"
      config.since_tag = "v#{latest_stable_version}"
      config.release_branch = "chef-12"
      config.max_issues = 0
      config.add_issues_wo_labels = false
      config.header = "This changelog reflects the current state of chef's chef-12 branch on github and may not reflect the current released version of chef, which is [![Gem Version](https://badge.fury.io/rb/chef.svg)](https://badge.fury.io/rb/chef)."
    end
  end

  task :changelog => "changelog:update"
rescue LoadError
  puts "github_changelog_generator is not available. gem install github_changelog_generator to generate changelogs"
end
