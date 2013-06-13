#
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'spec_helper'
require 'chef/mixin/shell_out'
require 'tmpdir'
require 'shellwords'

# Deploy relies heavily on symlinks, so it doesn't work on windows.
describe Chef::Resource::Git do
  include Chef::Mixin::ShellOut
  let(:file_cache_path) { Dir.mktmpdir }
  # Some versions of git complains when the deploy directory is
  # already created. Here we intentionally don't create the deploy
  # directory beforehand.
  let(:base_dir_path) { Dir.mktmpdir }
  let(:deploy_directory) { File.join(base_dir_path, make_tmpname("git_base")) }

  let(:node) do
    Chef::Node.new.tap do |n|
      n.name "rspec-test"
      n.consume_external_attrs(@ohai.data, {})
    end
  end

  let(:event_dispatch) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, event_dispatch) }

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
  let(:rev_head) { "d294fbfd05aa7709ad9a9b8ef6343b17d355bf5f"}

  let(:git_user_config) do
    <<-E
[user]
  name = frodoTbaggins
  email = frodo@shire.org
E
  end

  before(:each) do
    Chef::Log.level = :warn # silence git command live streams
    @old_file_cache_path = Chef::Config[:file_cache_path]
    shell_out!("git clone \"#{git_bundle_repo}\" example", :cwd => origin_repo_dir)
    File.open("#{origin_repo}/.git/config", "a+") {|f| f.print(git_user_config) }
    Chef::Config[:file_cache_path] = file_cache_path
  end

  after(:each) do
    Chef::Config[:file_cache_path] = @old_file_cache_path
    FileUtils.remove_entry_secure deploy_directory if File.exist?(deploy_directory)
    FileUtils.remove_entry_secure file_cache_path
  end

  after(:all) do
    FileUtils.remove_entry_secure origin_repo_dir
  end

  before(:all) do
    @ohai = Ohai::System.new
    @ohai.require_plugin("os")
  end

  context "working with pathes with special characters" do
    let(:path_with_spaces) { "#{origin_repo_dir}/path with spaces" }

    before(:each) do
      FileUtils.mkdir(path_with_spaces)
      FileUtils.cp(git_bundle_repo, path_with_spaces)
    end

    it "clones a repository with a space in the path" do
      Chef::Resource::Git.new(deploy_directory, run_context).tap do |r|
        r.repository "#{path_with_spaces}/example-repo.gitbundle"
      end.run_action(:sync)
    end
  end

  context "when deploying from an annotated tag" do
    let(:basic_git_resource) do
      Chef::Resource::Git.new(deploy_directory, run_context).tap do |r|
        r.repository origin_repo
        r.revision "v1.0.0"
      end
    end

    # We create a copy of the basic_git_resource so that we can run
    # the resource again and verify that it doesn't update.
    let(:copy_git_resource) do
      Chef::Resource::Git.new(deploy_directory, run_context).tap do |r|
        r.repository origin_repo
        r.revision "v1.0.0"
      end
    end

    it "checks out the revision pointed to by the tag commit, not the tag commit itself" do
      basic_git_resource.run_action(:sync)
      head_rev = shell_out!('git rev-parse HEAD', :cwd => deploy_directory, :returns => [0]).stdout.strip
      head_rev.should == v1_commit
      # also verify the tag commit itself is what we expect as an extra sanity check
      rev = shell_out!('git rev-parse v1.0.0', :cwd => deploy_directory, :returns => [0]).stdout.strip
      rev.should == v1_tag
    end

    it "doesn't update if up-to-date" do
      # this used to fail because we didn't resolve the annotated tag
      # properly to the pointed to commit.
      basic_git_resource.run_action(:sync)
      head_rev = shell_out!('git rev-parse HEAD', :cwd => deploy_directory, :returns => [0]).stdout.strip
      head_rev.should == v1_commit

      copy_git_resource.run_action(:sync)
      copy_git_resource.should_not be_updated
    end
  end

  context "when deploying from a SHA revision" do
    let(:basic_git_resource) do
      Chef::Resource::Git.new(deploy_directory, run_context).tap do |r|
        r.repository git_bundle_repo
      end
    end

    # We create a copy of the basic_git_resource so that we can run
    # the resource again and verify that it doesn't update.
    let(:copy_git_resource) do
      Chef::Resource::Git.new(deploy_directory, run_context).tap do |r|
        r.repository origin_repo
      end
    end

    it "checks out the expected revision ed18" do
      basic_git_resource.revision rev_foo
      basic_git_resource.run_action(:sync)
      head_rev = shell_out!('git rev-parse HEAD', :cwd => deploy_directory, :returns => [0]).stdout.strip
      head_rev.should == rev_foo
    end

    it "doesn't update if up-to-date" do
      basic_git_resource.revision rev_foo
      basic_git_resource.run_action(:sync)
      head_rev = shell_out!('git rev-parse HEAD', :cwd => deploy_directory, :returns => [0]).stdout.strip
      head_rev.should == rev_foo

      copy_git_resource.revision rev_foo
      copy_git_resource.run_action(:sync)
      copy_git_resource.should_not be_updated
    end

    it "checks out the expected revision 972d" do
      basic_git_resource.revision rev_testing
      basic_git_resource.run_action(:sync)
      head_rev = shell_out!('git rev-parse HEAD', :cwd => deploy_directory, :returns => [0]).stdout.strip
      head_rev.should == rev_testing
    end
  end

  context "when deploying from a revision named 'HEAD'" do
    let(:basic_git_resource) do
      Chef::Resource::Git.new(deploy_directory, run_context).tap do |r|
        r.repository origin_repo
        r.revision 'HEAD'
      end
    end

    it "checks out the expected revision" do
      basic_git_resource.run_action(:sync)
      head_rev = shell_out!('git rev-parse HEAD', :cwd => deploy_directory, :returns => [0]).stdout.strip
      head_rev.should == rev_head
    end
  end

  context "when deploying from the default revision" do
    let(:basic_git_resource) do
      Chef::Resource::Git.new(deploy_directory, run_context).tap do |r|
        r.repository origin_repo
        # use default
      end
    end

    it "checks out HEAD as the default revision" do
      basic_git_resource.run_action(:sync)
      head_rev = shell_out!('git rev-parse HEAD', :cwd => deploy_directory, :returns => [0]).stdout.strip
      head_rev.should == rev_head
    end
  end

  context "when dealing with a repo with a degenerate tag named 'HEAD'" do
    before do
      shell_out!("git tag -m\"degenerate tag\" HEAD ed181b3419b6f489bedab282348162a110d6d3a1",
                 :cwd => origin_repo)
    end

    let(:basic_git_resource) do
      Chef::Resource::Git.new(deploy_directory, run_context).tap do |r|
        r.repository origin_repo
        r.revision 'HEAD'
      end
    end

    let(:git_resource_default_rev) do
      Chef::Resource::Git.new(deploy_directory, run_context).tap do |r|
        r.repository origin_repo
        # use default of revision
      end
    end

    it "checks out the (master) HEAD revision and ignores the tag" do
      basic_git_resource.run_action(:sync)
      head_rev = shell_out!('git rev-parse HEAD',
                            :cwd => deploy_directory,
                            :returns => [0]).stdout.strip
      head_rev.should == rev_head
    end

    it "checks out the (master) HEAD revision when no revision is specified (ignores tag)" do
      git_resource_default_rev.run_action(:sync)
      head_rev = shell_out!('git rev-parse HEAD',
                            :cwd => deploy_directory,
                            :returns => [0]).stdout.strip
      head_rev.should == rev_head
    end

  end
end
