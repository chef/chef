#
# Author:: Seth Falcon (<seth@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"
require "tmpdir"

# Deploy relies heavily on symlinks, so it doesn't work on windows.
describe Chef::Resource::Git do
  include RecipeDSLHelper

  # Some versions of git complains when the deploy directory is
  # already created. Here we intentionally don't create the deploy
  # directory beforehand.
  let(:base_dir_path) { Dir.mktmpdir }
  let(:deploy_directory) { File.join(base_dir_path, make_tmpname("git_base")) }

  # These tests use git's bundle feature, which is a way to export an entire
  # git repo (or subset of commits) as a single file.
  #
  # Generally you can treat a git bundle as a regular git remote.
  #
  # See also: http://git-scm.com/2010/03/10/bundles.html
  #
  # Beware that git bundles don't behave exactly the same as real
  # remotes. To get closer to real remotes, we'll create a local clone
  # of the bundle to use as a remote for the tests. This at least
  # gives the expected responses for ls-remote using git version
  # 1.7.12.4
  let(:git_bundle_repo) { File.expand_path("git_bundles/example-repo.gitbundle", CHEF_SPEC_DATA) }
  let(:origin_repo_dir) { Dir.mktmpdir }
  let(:origin_repo) { "#{origin_repo_dir}/example" }

  # This is the fourth version
  let(:v1_commit) { "bc5ec79931ae74089aeadca6edc173527613e6d9" }
  let(:v1_tag) { "9b73fb5e316bfaff7b822b0ccb3e1e08f9885085" }
  let(:rev_foo) { "ed181b3419b6f489bedab282348162a110d6d3a1" }
  let(:rev_testing) { "972d153654503bccec29f630c5dd369854a561e8" }
  let(:rev_head) { "d294fbfd05aa7709ad9a9b8ef6343b17d355bf5f" }

  before(:each) do
    shell_out!("git", "clone", git_bundle_repo, "example", cwd: origin_repo_dir)
    File.open("#{origin_repo}/.git/config", "a+") do |f|
      f.print <<~EOF
        [user]
          name = frodoTbaggins
          email = frodo@shire.org
      EOF
    end
  end

  after(:each) do
    FileUtils.remove_entry_secure deploy_directory if File.exist?(deploy_directory)
    FileUtils.remove_entry_secure base_dir_path
    FileUtils.remove_entry_secure origin_repo_dir
  end

  def expect_revision_to_be(revision, version)
    rev_ver = shell_out!("git", "rev-parse", revision, cwd: deploy_directory).stdout.strip
    expect(rev_ver).to eq(version)
  end

  def expect_branch_to_be(branch)
    head_branch = shell_out!("git name-rev --name-only HEAD", cwd: deploy_directory).stdout.strip
    expect(head_branch).to eq(branch)
  end

  context "working with pathes with special characters" do
    let(:path_with_spaces) { "#{origin_repo_dir}/path with spaces" }

    before(:each) do
      FileUtils.mkdir(path_with_spaces)
      FileUtils.cp(git_bundle_repo, path_with_spaces)
    end

    it "clones a repository with a space in the path" do
      repo = "#{path_with_spaces}/example-repo.gitbundle"
      git(deploy_directory) do
        repository repo
      end.should_be_updated
      expect_revision_to_be("HEAD", rev_head)
    end
  end

  context "when deploying from an annotated tag" do
    it "checks out the revision pointed to by the tag commit, not the tag commit itself" do
      git deploy_directory do
        repository origin_repo
        revision "v1.0.0"
      end.should_be_updated
      expect_revision_to_be("HEAD", v1_commit)
      expect_branch_to_be("tags/v1.0.0^0") # detached
      # also verify the tag commit itself is what we expect as an extra sanity check
      expect_revision_to_be("v1.0.0", v1_tag)
    end

    it "doesn't update if up-to-date" do
      git deploy_directory do
        repository origin_repo
        revision "v1.0.0"
      end.should_be_updated
      git deploy_directory do
        repository origin_repo
        revision "v1.0.0"
        expect_branch_to_be("tags/v1.0.0^0") # detached
      end.should_not_be_updated
    end
  end

  context "when deploying from a SHA revision" do
    it "checks out the expected revision ed18" do
      git deploy_directory do
        repository git_bundle_repo
        revision rev_foo
      end.should_be_updated
      expect_revision_to_be("HEAD", rev_foo)
      expect_branch_to_be("master~1") # detached
    end

    it "checks out the expected revision ed18 to a local branch" do
      git deploy_directory do
        repository git_bundle_repo
        revision rev_foo
        checkout_branch "deploy"
      end.should_be_updated
      expect_revision_to_be("HEAD", rev_foo)
      expect_branch_to_be("deploy") # detached
    end

    it "doesn't update if up-to-date" do
      git deploy_directory do
        repository git_bundle_repo
        revision rev_foo
      end.should_be_updated
      expect_revision_to_be("HEAD", rev_foo)

      git deploy_directory do
        repository origin_repo
        revision rev_foo
      end.should_not_be_updated
      expect_branch_to_be("master~1") # detached
    end

    it "checks out the expected revision 972d" do
      git deploy_directory do
        repository git_bundle_repo
        revision rev_testing
      end.should_be_updated
      expect_revision_to_be("HEAD", rev_testing)
      expect_branch_to_be("master~2") # detached
    end

    it "checks out the expected revision 972d to a local branch" do
      git deploy_directory do
        repository git_bundle_repo
        revision rev_testing
        checkout_branch "deploy"
      end.should_be_updated
      expect_revision_to_be("HEAD", rev_testing)
      expect_branch_to_be("deploy")
    end
  end

  context "when deploying from a revision named 'HEAD'" do
    it "checks out the expected revision" do
      git deploy_directory do
        repository origin_repo
        revision "HEAD"
      end.should_be_updated
      expect_revision_to_be("HEAD", rev_head)
      expect_branch_to_be("master")
    end

    it "checks out the expected revision, and is idempotent" do
      git deploy_directory do
        repository origin_repo
        revision "HEAD"
      end.should_be_updated
      git deploy_directory do
        repository origin_repo
        revision "HEAD"
      end.should_not_be_updated
      expect_revision_to_be("HEAD", rev_head)
      expect_branch_to_be("master")
    end

    it "checks out the expected revision to a local branch" do
      git deploy_directory do
        repository origin_repo
        revision "HEAD"
        checkout_branch "deploy"
      end.should_be_updated
      expect_revision_to_be("HEAD", rev_head)
      expect_branch_to_be("deploy")
    end
  end

  context "when deploying from the default revision" do
    it "checks out HEAD as the default revision" do
      git deploy_directory do
        repository origin_repo
      end.should_be_updated
      expect_revision_to_be("HEAD", rev_head)
      expect_branch_to_be("master")
    end

    it "checks out HEAD as the default revision, and is idempotent" do
      git deploy_directory do
        repository origin_repo
      end.should_be_updated
      git deploy_directory do
        repository origin_repo
      end.should_not_be_updated
      expect_revision_to_be("HEAD", rev_head)
      expect_branch_to_be("master")
    end

    it "checks out HEAD as the default revision to a local branch" do
      git deploy_directory do
        repository origin_repo
        checkout_branch "deploy"
      end.should_be_updated
      expect_revision_to_be("HEAD", rev_head)
      expect_branch_to_be("deploy")
    end
  end

  context "when updating a branch that's already checked out out" do
    it "checks out master, commits to the repo, and checks out the latest changes" do
      git deploy_directory do
        repository origin_repo
        revision "master"
        action :sync
      end.should_be_updated

      # We don't have a way to test a commit in the git bundle
      # Revert to a previous commit in the same branch and make sure we can still sync.
      shell_out!("git", "reset", "--hard", rev_foo, cwd: deploy_directory)

      git deploy_directory do
        repository origin_repo
        revision "master"
        action :sync
      end.should_be_updated
      expect_revision_to_be("HEAD", rev_head)
      expect_branch_to_be("master")
    end
  end

  context "when dealing with a repo with a degenerate tag named 'HEAD'", not_supported_on_windows: true, git_no_tag_head: true do
    before do
      shell_out!("git", "tag", "-m \"degenerate tag\"", "HEAD", "ed181b3419b6f489bedab282348162a110d6d3a1", cwd: origin_repo)
    end

    it "checks out the (master) HEAD revision and ignores the tag" do
      git deploy_directory do
        repository origin_repo
        revision "HEAD"
      end.should_be_updated
      expect_revision_to_be("HEAD", rev_head)
      expect_branch_to_be("master")
    end

    it "checks out the (master) HEAD revision and ignores the tag, and is idempotent" do
      git deploy_directory do
        repository origin_repo
        revision "HEAD"
      end.should_be_updated
      git deploy_directory do
        repository origin_repo
        revision "HEAD"
      end.should_not_be_updated
      expect_revision_to_be("HEAD", rev_head)
      expect_branch_to_be("master")
    end

    it "checks out the (master) HEAD revision and ignores the tag to a local branch" do
      git deploy_directory do
        repository origin_repo
        revision "HEAD"
        checkout_branch "deploy"
      end.should_be_updated
      expect_revision_to_be("HEAD", rev_head)
      expect_branch_to_be("deploy")
    end

    it "checks out the (master) HEAD revision when no revision is specified (ignores tag)" do
      git deploy_directory do
        repository origin_repo
      end.should_be_updated
      expect_revision_to_be("HEAD", rev_head)
      expect_branch_to_be("master")
    end

    it "checks out the (master) HEAD revision when no revision is specified (ignores tag), and is idempotent" do
      git deploy_directory do
        repository origin_repo
      end.should_be_updated
      git deploy_directory do
        repository origin_repo
      end.should_not_be_updated
      expect_revision_to_be("HEAD", rev_head)
      expect_branch_to_be("master")
    end

    it "checks out the (master) HEAD revision when no revision is specified (ignores tag) to a local branch" do
      git deploy_directory do
        repository origin_repo
        checkout_branch "deploy"
      end.should_be_updated
      expect_revision_to_be("HEAD", rev_head)
      expect_branch_to_be("deploy")
    end
  end
end
