begin
  require "github_changelog_generator/task"

  # Take the current changelog and move it to HISTORY.md. Should be done when
  # cutting a release
  task :archive_changelog do
    changelog = File.readlines("CHANGELOG.md")
    File.open("HISTORY.md", "w+") { |f| f.write(changelog[2..-1].join("")) }
  end

  # Run this to just update the changelog for the current release. This will
  # take what is in History and generate a changelog of PRs between the most
  # recent tag in HISTORY.md and HEAD.
  GitHubChangelogGenerator::RakeTask.new :update_changelog do |config|
    config.future_release = Chef::VERSION
    config.between_tags = ["v#{Chef::VERSION}"]
    config.max_issues = 0
    config.add_issues_wo_labels = false
    config.enhancement_labels = "enhancement,Enhancement,New Feature,Feature".split(",")
    config.bug_labels = "bug,Bug,Improvement,Upstream Bug".split(",")
    config.exclude_labels = "duplicate,question,invalid,wontfix,no_changelog,Exclude From Changelog,Question,Discussion".split(",")
    config.header = "This changelog reflects the current state of chef's master branch on github and may not reflect the current released version of chef, which is [![Gem Version](https://badge.fury.io/rb/chef.svg)](https://badge.fury.io/rb/chef)"
  end

  task :changelog do
    Rake::Task["archive_changelog"].execute
    Rake::Task["update_changelog"].execute
  end
rescue LoadError
  puts "github_changelog_generator is not available. gem install github_changelog_generator to generate changelogs"
end
