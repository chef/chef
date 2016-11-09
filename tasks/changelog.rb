begin
  require "github_changelog_generator/task"

  namespace :changelog do
    # Take the current changelog and move it to HISTORY.md. Removes lines that
    # would get duplicated the next time we pull HISTORY into the CHANGELOG.
    task :archive do
      changelog = File.readlines("CHANGELOG.md")
      File.open("HISTORY.md", "w+") { |f| f.write(changelog[2..-4].join("")) }
    end

    # Run this to just update the changelog for the current release. This will
    # take what is in History and generate a changelog of PRs between the most
    # recent tag in HISTORY.md and HEAD.
    GitHubChangelogGenerator::RakeTask.new :update do |config|
      config.future_release = Chef::VERSION
      config.between_tags = ["v#{Chef::VERSION}"]
      config.max_issues = 0
      config.add_issues_wo_labels = false
      config.enhancement_labels = "enhancement,Enhancement,New Feature,Feature".split(",")
      config.bug_labels = "bug,Bug,Improvement,Upstream Bug".split(",")
      config.exclude_labels = "duplicate,question,invalid,wontfix,no_changelog,Exclude From Changelog,Question,Discussion".split(",")
      config.header = "This changelog reflects the current state of chef's master branch on github and may not reflect the current released version of chef, which is [![Gem Version](https://badge.fury.io/rb/chef.svg)](https://badge.fury.io/rb/chef)"
    end
  end

  task :changelog => "changelog:update"
rescue LoadError
  puts "github_changelog_generator is not available. gem install github_changelog_generator to generate changelogs"
end
