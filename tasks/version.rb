#
# Copyright:: Copyright 2017 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

BUMP_PATCH_LABEL = "Version: Bump Patch"
BUMP_MINOR_LABEL = "Version: Bump Minor"
BUMP_MAJOR_LABEL = "Version: Bump Major"

# Temporary setting to keep current behavior. If there is no
# label, bump patch. Setting this to false will cause PRs
# without a version label to _not_ get a version bump.
BUMP_PATH_WITH_NO_LABEL = true

task :ci_version_bump do
  begin
    require "rake"
    require "octokit"

    client = Octokit::Client.new(:netrc => true)
    begin
      issue_id = `git log --format=%B -n 1 HEAD`.match(/Merge pull request #(\d+)/)[1]
      puts "Getting Issue labels from PR ##{issue_id}"
    rescue NoMethodError
      puts "This commit was not associated with a Github PR - not bumping the version."
      exit 0
    end

    issue = github.issue("chef/chef", issue_id)
    labels = issue[:labels].select { |i| [BUMP_PATCH_LABEL, BUMP_MINOR_LABEL, BUMP_MAJOR_LABEL].include?(i[:name]) }

    if labels.length < 1 && !BUMP_PATH_WITH_NO_LABEL
      puts "We didn't find any valid Version labels on the PR."
      exit 0
    end

    if labels.length > 1
      puts "There can only be one valid Version label per PR."
      raise
    end

    case labels.first[:name]
    when BUMP_MAJOR_LABEL
      Rake::Task["version:bump_major"].invoke
    when BUMP_MINOR_LABEL
      Rake::Task["version:bump_minor"].invoke
    else
      Rake::Task["version:bump_patch"].invoke
    end

    Rake::Task["version:update"].invoke

    # We want to log errors that occur in the following tasks, but we don't
    # want them to stop an otherwise valid version bump from progressing.
    begin
      Rake::Task["changelog:update"].invoke
    rescue Exception => e
      puts "There was an error updating the CHANGELOG"
      puts e
    end

    begin
      Rake::Task["update_dockerfile"].invoke
    rescue Exception => e
      puts "There was an error updating the Dockerfile"
      puts e
    end
  end
end
