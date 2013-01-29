#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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
require 'tmpdir'

# Deploy relies heavily on symlinks, so it doesn't work on windows.
describe Chef::Resource::DeployRevision, :unix_only => true do

  let(:file_cache_path) { Dir.mktmpdir }
  let(:deploy_directory) { Dir.mktmpdir }

  # By making restart or other operations write to this file, we can externally
  # track the order in which those operations happened.
  let(:observe_order_file) { Tempfile.new("deploy-resource-observe-operations") }

  before do
    @old_file_cache_path = Chef::Config[:file_cache_path]
    Chef::Config[:file_cache_path] = file_cache_path
  end

  after do
    Chef::Config[:file_cache_path] = @old_file_cache_path
    FileUtils.remove_entry_secure deploy_directory if File.exist?(deploy_directory)
    FileUtils.remove_entry_secure file_cache_path
    observe_order_file.close
    FileUtils.remove_entry_secure observe_order_file.path
  end

  before(:all) do
    @ohai = Ohai::System.new
    @ohai.require_plugin("os")
  end

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
  let(:git_bundle_repo) { File.expand_path("git_bundles/sinatra-test-app.gitbundle", CHEF_SPEC_DATA) }

  let(:git_bundle_with_in_repo_callbacks) { File.expand_path("git_bundles/sinatra-test-app-with-callback-files.gitbundle", CHEF_SPEC_DATA) }

  let(:git_bundle_with_in_repo_symlinks) { File.expand_path("git_bundles/sinatra-test-app-with-symlinks.gitbundle", CHEF_SPEC_DATA) }

  # This is the fourth version
  let(:latest_rev) { "3eb5ca6c353c83d9179dd3b29347539829b401f3" }

  # This is the third version
  let(:previous_rev) { "6d19a6dbecc8e37f5b2277345885c0c783eb8fb1" }

  # This is the sixth version, it is on the "with-deploy-scripts" branch
  let(:rev_with_in_repo_callbacks) { "2404d015882659754bdb93ad6e4b4d3d02691a82" }

  # This is the fifth version in the "with-symlinks" branch
  let(:rev_with_in_repo_symlinks) { "5a4748c52aaea8250b4346a9b8ede95ee3755e28" }

  # Read values from the +observe_order_file+ and split each line. This way you
  # can see in which order things really happened.
  def actual_operations_order
    IO.read(observe_order_file.path).split("\n").map(&:strip)
  end

  # 1. touch `restart.txt` in cwd so we know that the command is run with the
  #    right cwd.
  # 2. Append +tag+ to the `observe_order_file` so we can check the order in
  #    which operations happen later in the test.
  def shell_restart_command(tag)
    "touch restart.txt && echo '#{tag}' >> #{observe_order_file.path}"
  end

  let(:basic_deploy_resource) do
    Chef::Resource::DeployRevision.new(deploy_directory, run_context).tap do |r|
      r.repo git_bundle_repo
      r.symlink_before_migrate({})
      r.symlinks({})
    end
  end

  let(:deploy_to_latest_rev) do
    basic_deploy_resource.dup.tap do |r|
      r.revision(latest_rev)
      r.restart_command shell_restart_command(:deploy_to_latest_rev)
    end
  end

  let(:deploy_to_previous_rev) do
    basic_deploy_resource.dup.tap do |r|
      r.revision(previous_rev)
      r.restart_command shell_restart_command(:deploy_to_previous_rev)
    end
  end

  let(:deploy_to_latest_rev_again) do
    basic_deploy_resource.dup.tap do |r|
      r.revision(latest_rev)
      r.restart_command shell_restart_command(:deploy_to_latest_rev_again)
    end
  end

  # Computes the full path for +path+ relative to the deploy directory
  def rel_path(path)
    File.expand_path(path, deploy_directory)
  end

  def actual_current_rev
    Dir.chdir(rel_path("current")) do
      `git rev-parse HEAD`.strip
    end
  end

  def self.the_app_is_deployed_at_revision(target_rev_spec)
    it "deploys the app to the target revision (#{target_rev_spec})" do
      target_rev = send(target_rev_spec)

      File.should exist(rel_path("current"))

      actual_current_rev.should == target_rev

      # Is the app code actually there?
      File.should exist(rel_path("current/app/app.rb"))
    end
  end

  context "when deploying a simple app" do
    describe "for the first time, with the required directory layout precreated" do
      before do
        FileUtils.mkdir_p(rel_path("releases"))
        FileUtils.mkdir_p(rel_path("shared"))
        deploy_to_latest_rev.run_action(:deploy)
      end

      the_app_is_deployed_at_revision(:latest_rev)

      it "restarts the application" do
        File.should exist(rel_path("current/restart.txt"))
        actual_operations_order.should == %w[deploy_to_latest_rev]
      end

      it "is marked as updated" do
        deploy_to_latest_rev.should be_updated_by_last_action
      end
    end

    describe "back to a previously deployed revision, with the directory structure precreated" do
      before do
        FileUtils.mkdir_p(rel_path("releases"))
        FileUtils.mkdir_p(rel_path("shared"))

        deploy_to_latest_rev.run_action(:deploy)
        deploy_to_previous_rev.run_action(:deploy)
        deploy_to_latest_rev_again.run_action(:deploy)
      end

      the_app_is_deployed_at_revision(:latest_rev)

      it "restarts the application after rolling back" do
        actual_operations_order.should == %w[deploy_to_latest_rev deploy_to_previous_rev deploy_to_latest_rev_again]
      end

      it "is marked updated" do
        deploy_to_latest_rev_again.should be_updated_by_last_action
      end

      it "deploys the right code" do
        IO.read(rel_path("current/app/app.rb")).should include("this is the fourth version of the app")
      end
    end

    describe "for the first time, with no existing directory layout" do
      before do
        deploy_to_latest_rev.run_action(:deploy)
      end

      it "creates the required directory tree" do
        File.should be_directory(rel_path("releases"))
        File.should be_directory(rel_path("shared"))
        File.should be_directory(rel_path("releases/#{latest_rev}"))

        File.should be_directory(rel_path("current/tmp"))
        File.should be_directory(rel_path("current/config"))
        File.should be_directory(rel_path("current/public"))

        File.should be_symlink(rel_path("current"))
        File.readlink(rel_path("current")).should == rel_path("releases/#{latest_rev}")
      end

      the_app_is_deployed_at_revision(:latest_rev)

      it "restarts the application" do
        File.should exist(rel_path("current/restart.txt"))
        actual_operations_order.should == %w[deploy_to_latest_rev]
      end

      it "is marked as updated" do
        deploy_to_latest_rev.should be_updated_by_last_action
      end
    end

    describe "again to the current revision" do
      before do
        deploy_to_latest_rev.run_action(:deploy)
        deploy_to_latest_rev.run_action(:deploy)
      end

      the_app_is_deployed_at_revision(:latest_rev)

      it "does not restart the app" do
        actual_operations_order.should == %w[deploy_to_latest_rev]
      end

      it "is not marked updated" do
        deploy_to_latest_rev.should_not be_updated_by_last_action
      end

    end

    describe "again with force_deploy" do
      before do
        deploy_to_latest_rev.run_action(:force_deploy)
        deploy_to_latest_rev_again.run_action(:force_deploy)
      end

      the_app_is_deployed_at_revision(:latest_rev)

      it "restarts the app" do
        actual_operations_order.should == %w[deploy_to_latest_rev deploy_to_latest_rev_again]
      end

      it "is marked updated" do
        deploy_to_latest_rev.should be_updated_by_last_action
      end

    end

    describe "again to a new revision" do
      before do
        deploy_to_previous_rev.run_action(:deploy)
        deploy_to_latest_rev.run_action(:deploy)
      end

      the_app_is_deployed_at_revision(:latest_rev)

      it "restarts the application after the new deploy" do
        actual_operations_order.should == %w[deploy_to_previous_rev deploy_to_latest_rev]
      end

      it "is marked updated" do
        deploy_to_previous_rev.should be_updated_by_last_action
      end
    end

    describe "back to a previously deployed revision (implicit rollback)" do
      before do
        deploy_to_latest_rev.run_action(:deploy)
        deploy_to_previous_rev.run_action(:deploy)
        deploy_to_latest_rev_again.run_action(:deploy)
      end

      the_app_is_deployed_at_revision(:latest_rev)

      it "restarts the application after rolling back" do
        actual_operations_order.should == %w[deploy_to_latest_rev deploy_to_previous_rev deploy_to_latest_rev_again]
      end

      it "is marked updated" do
        deploy_to_latest_rev_again.should be_updated_by_last_action
      end

      it "deploys the right code" do
        IO.read(rel_path("current/app/app.rb")).should include("this is the fourth version of the app")
      end
    end

    # CHEF-3435
    describe "to a deploy_to path that does not yet exist" do

      let(:top_level_tmpdir) { Dir.mktmpdir }

      # override top level deploy_directory let block with one that is two
      # directories deeper
      let(:deploy_directory) { File.expand_path("nested/deeper", top_level_tmpdir) }

      after do
        FileUtils.remove_entry_secure top_level_tmpdir
      end

      before do
        File.should_not exist(deploy_directory)
        deploy_to_latest_rev.run_action(:deploy)
      end

      it "creates the required directory tree" do
        File.should be_directory(rel_path("releases"))
        File.should be_directory(rel_path("shared"))
        File.should be_directory(rel_path("releases/#{latest_rev}"))

        File.should be_directory(rel_path("current/tmp"))
        File.should be_directory(rel_path("current/config"))
        File.should be_directory(rel_path("current/public"))

        File.should be_symlink(rel_path("current"))
        File.readlink(rel_path("current")).should == rel_path("releases/#{latest_rev}")
      end

      the_app_is_deployed_at_revision(:latest_rev)

    end
  end

  context "when deploying an app with inline recipe callbacks" do

    # Use closures to capture and mutate this variable. This allows us to track
    # ordering of operations.
    callback_order = []

    let(:deploy_to_latest_with_inline_recipes) do
      deploy_to_latest_rev.dup.tap do |r|
        r.symlink_before_migrate "config/config.ru" => "config.ru"
        r.before_migrate do
          callback_order << :before_migrate

          file "#{release_path}/before_migrate.txt" do
            # The content here isn't relevant, but it gets printed when running
            # the tests. Could be handy for debugging.
            content callback_order.inspect
          end
        end
        r.before_symlink do
          callback_order << :before_symlink

          current_release_path = release_path
          ruby_block "ensure before symlink" do
            block do
              if ::File.exist?(::File.join(current_release_path, "/tmp"))
                raise "Ordering issue with provider, expected symlinks to not have been created"
              end
            end
          end

          file "#{release_path}/before_symlink.txt" do
            content callback_order.inspect
          end
        end
        r.before_restart do
          callback_order << :before_restart

          current_release_path = release_path
          ruby_block "ensure after symlink" do
            block do
              unless ::File.exist?(::File.join(current_release_path, "/tmp"))
                raise "Ordering issue with provider, expected symlinks to have been created"
              end
            end
          end

          file "#{release_path}/tmp/before_restart.txt" do
            content callback_order.inspect
          end
        end
        r.after_restart do
          callback_order << :after_restart
          file "#{release_path}/tmp/after_restart.txt" do
            content callback_order.inspect
          end
        end
      end
    end

    before do
      callback_order.clear # callback_order variable is global for this context group
      deploy_to_latest_with_inline_recipes.run_action(:deploy)
    end

    the_app_is_deployed_at_revision(:latest_rev)

    it "is marked updated" do
      deploy_to_latest_with_inline_recipes.should be_updated_by_last_action
    end

    it "calls the callbacks in order" do
      callback_order.should == [:before_migrate, :before_symlink, :before_restart, :after_restart]
    end

    it "runs chef resources in the callbacks" do
      File.should exist(rel_path("current/before_migrate.txt"))
      File.should exist(rel_path("current/before_symlink.txt"))
      File.should exist(rel_path("current/tmp/before_restart.txt"))
      File.should exist(rel_path("current/tmp/after_restart.txt"))
    end
  end

  context "when deploying an app with in-repo callback scripts" do
    let(:deploy_with_in_repo_callbacks) do
      basic_deploy_resource.dup.tap do |r|
        r.repo git_bundle_with_in_repo_callbacks
        r.revision rev_with_in_repo_callbacks
      end
    end

    before do
      deploy_with_in_repo_callbacks.run_action(:deploy)
    end

    the_app_is_deployed_at_revision(:rev_with_in_repo_callbacks)

    it "runs chef resources in the callbacks" do
      File.should exist(rel_path("current/before_migrate.txt"))
      File.should exist(rel_path("current/before_symlink.txt"))
      File.should exist(rel_path("current/tmp/before_restart.txt"))
      File.should exist(rel_path("current/tmp/after_restart.txt"))
    end

  end

  context "when deploying an app with migrations" do
    let(:deploy_with_migration) do
      basic_deploy_resource.dup.tap do |r|

        # Need this so we can call methods from this test inside the inline
        # recipe callbacks
        spec_context = self

        r.revision latest_rev

        # enable migrations
        r.migrate true
        # abuse `shell_restart_command` so we can observe order of when the
        # miration command gets run
        r.migration_command shell_restart_command("migration")
        r.before_migrate do

          # inline recipe callbacks don't cwd, so you have to get the release
          # directory as a local and "capture" it in the closure.
          current_release = release_path
          execute spec_context.shell_restart_command("before_migrate") do
            cwd current_release
          end
        end
        r.before_symlink do
          current_release = release_path
          execute spec_context.shell_restart_command("before_symlink") do
            cwd current_release
          end
        end

        r.before_restart do
          current_release = release_path
          execute spec_context.shell_restart_command("before_restart") do
            cwd current_release
          end
        end

        r.after_restart do
          current_release = release_path
          execute spec_context.shell_restart_command("after_restart") do
            cwd current_release
          end
        end

      end
    end

    before do
      deploy_with_migration.run_action(:deploy)
    end

    it "runs migrations in between the before_migrate and before_symlink steps" do
      actual_operations_order.should == %w[before_migrate migration before_symlink before_restart after_restart]
    end
  end

  context "when deploying an app with in-repo symlinks" do
    let(:deploy_with_in_repo_symlinks) do
      basic_deploy_resource.dup.tap do |r|
        r.repo git_bundle_with_in_repo_symlinks
        r.revision rev_with_in_repo_symlinks
      end
    end

    it "should not raise an exception calling File.utime on symlinks" do
      lambda { deploy_with_in_repo_symlinks.run_action(:deploy) }.should_not raise_error
    end
  end
end


