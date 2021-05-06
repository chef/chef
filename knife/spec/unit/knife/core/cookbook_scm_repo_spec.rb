#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "knife_spec_helper"
require "chef/knife/core/cookbook_scm_repo"

describe Chef::Knife::CookbookSCMRepo do
  before do
    @repo_path = File.join(CHEF_SPEC_DATA, "cookbooks")
    @stdout, @stderr, @stdin = StringIO.new, StringIO.new, StringIO.new
    @ui = Chef::Knife::UI.new(@stdout, @stderr, @stdin, {})
    @cookbook_repo = Chef::Knife::CookbookSCMRepo.new(@repo_path, @ui, default_branch: "master")

    @branch_list = Mixlib::ShellOut.new
    @branch_list.stdout.replace(<<-BRANCHES)
  chef-vendor-apache2
  chef-vendor-build-essential
  chef-vendor-dynomite
  chef-vendor-ganglia
  chef-vendor-graphite
  chef-vendor-python
  chef-vendor-absent-new
    BRANCHES
  end

  it "has a path to the cookbook repo" do
    expect(@cookbook_repo.repo_path).to eq(@repo_path)
  end

  it "has a default branch" do
    expect(@cookbook_repo.default_branch).to eq("master")
  end

  describe "when sanity checking the repo" do
    it "exits when the directory does not exist" do
      expect(::File).to receive(:directory?).with(@repo_path).and_return(false)
      expect { @cookbook_repo.sanity_check }.to raise_error(SystemExit)
    end

    describe "and the repo dir exists" do
      before do
        allow(::File).to receive(:directory?).with(@repo_path).and_return(true)
      end

      it "exits when there is no git repo" do
        allow(::File).to receive(:directory?).with(/.*\.git/).and_return(false)
        expect { @cookbook_repo.sanity_check }.to raise_error(SystemExit)
      end

      describe "and the repo is a git repo" do
        before do
          allow(::File).to receive(:directory?).with(File.join(@repo_path, ".git")).and_return(true)
        end

        it "exits when the default branch doesn't exist" do
          @nobranches = Mixlib::ShellOut.new.tap { |s| s.stdout.replace "\n" }
          expect(@cookbook_repo).to receive(:shell_out!).with("git branch --no-color", cwd: @repo_path).and_return(@nobranches)
          expect { @cookbook_repo.sanity_check }.to raise_error(SystemExit)
        end

        describe "and the default branch exists" do
          before do
            @master_branch = Mixlib::ShellOut.new
            @master_branch.stdout.replace "* master\n"
            expect(@cookbook_repo).to receive(:shell_out!).with("git branch --no-color", cwd: @repo_path).and_return(@master_branch)
          end

          it "exits when the git repo is dirty" do
            @dirty_status = Mixlib::ShellOut.new
            @dirty_status.stdout.replace(<<-DIRTY)
 M chef/lib/chef/knife/cookbook_site_install.rb
            DIRTY
            expect(@cookbook_repo).to receive(:shell_out!).with("git status --porcelain", cwd: @repo_path).and_return(@dirty_status)
            expect { @cookbook_repo.sanity_check }.to raise_error(SystemExit)
          end

          describe "and the repo is clean" do
            before do
              @clean_status = Mixlib::ShellOut.new.tap { |s| s.stdout.replace("\n") }
              allow(@cookbook_repo).to receive(:shell_out!).with("git status --porcelain", cwd: @repo_path).and_return(@clean_status)
            end

            it "passes the sanity check" do
              @cookbook_repo.sanity_check
            end

          end
        end
      end
    end
  end

  it "resets to default state by checking out the default branch" do
    expect(@cookbook_repo).to receive(:shell_out!).with("git checkout master", cwd: @repo_path)
    @cookbook_repo.reset_to_default_state
  end

  it "determines if a the pristine copy branch exists" do
    expect(@cookbook_repo).to receive(:shell_out!).with("git branch --no-color", cwd: @repo_path).and_return(@branch_list)
    expect(@cookbook_repo.branch_exists?("chef-vendor-apache2")).to be_truthy
    expect(@cookbook_repo).to receive(:shell_out!).with("git branch --no-color", cwd: @repo_path).and_return(@branch_list)
    expect(@cookbook_repo.branch_exists?("chef-vendor-nginx")).to be_falsey
  end

  it "determines if a the branch not exists correctly without substring search" do
    expect(@cookbook_repo).to receive(:shell_out!).twice.with("git branch --no-color", cwd: @repo_path).and_return(@branch_list)
    expect(@cookbook_repo).not_to be_branch_exists("chef-vendor-absent")
    expect(@cookbook_repo).to be_branch_exists("chef-vendor-absent-new")
  end

  describe "when the pristine copy branch does not exist" do
    it "prepares for import by creating the pristine copy branch" do
      expect(@cookbook_repo).to receive(:shell_out!).with("git branch --no-color", cwd: @repo_path).and_return(@branch_list)
      expect(@cookbook_repo).to receive(:shell_out!).with("git checkout -b chef-vendor-nginx", cwd: @repo_path)
      @cookbook_repo.prepare_to_import("nginx")
    end
  end

  describe "when the pristine copy branch does exist" do
    it "prepares for import by checking out the pristine copy branch" do
      expect(@cookbook_repo).to receive(:shell_out!).with("git branch --no-color", cwd: @repo_path).and_return(@branch_list)
      expect(@cookbook_repo).to receive(:shell_out!).with("git checkout chef-vendor-apache2", cwd: @repo_path)
      @cookbook_repo.prepare_to_import("apache2")
    end
  end

  describe "when the pristine copy branch was not updated by the changes" do
    before do
      @updates = Mixlib::ShellOut.new
      @updates.stdout.replace("\n")
      allow(@cookbook_repo).to receive(:shell_out!).with("git status --porcelain -- apache2", cwd: @repo_path).and_return(@updates)
    end

    it "shows no changes in the pristine copy" do
      expect(@cookbook_repo.updated?("apache2")).to be_falsey
    end

    it "does nothing to finalize the updates" do
      expect(@cookbook_repo.finalize_updates_to("apache2", "1.2.3")).to be_falsey
    end
  end

  describe "when the pristine copy branch was updated by the changes" do
    before do
      @updates = Mixlib::ShellOut.new
      @updates.stdout.replace(" M cookbooks/apache2/recipes/default.rb\n")
      allow(@cookbook_repo).to receive(:shell_out!).with("git status --porcelain -- apache2", cwd: @repo_path).and_return(@updates)
    end

    it "shows changes in the pristine copy" do
      expect(@cookbook_repo.updated?("apache2")).to be_truthy
    end

    it "commits the changes to the repo and tags the commit" do
      expect(@cookbook_repo).to receive(:shell_out!).with("git add apache2", cwd: @repo_path)
      expect(@cookbook_repo).to receive(:shell_out!).with("git commit -m \"Import apache2 version 1.2.3\" -- apache2", cwd: @repo_path)
      expect(@cookbook_repo).to receive(:shell_out!).with("git tag -f cookbook-site-imported-apache2-1.2.3", cwd: @repo_path)
      expect(@cookbook_repo.finalize_updates_to("apache2", "1.2.3")).to be_truthy
    end
  end

  describe "when a custom default branch is specified" do
    before do
      @cookbook_repo = Chef::Knife::CookbookSCMRepo.new(@repo_path, @ui, default_branch: "develop")
    end

    it "resets to default state by checking out the default branch" do
      expect(@cookbook_repo).to receive(:shell_out!).with("git checkout develop", cwd: @repo_path)
      @cookbook_repo.reset_to_default_state
    end
  end
end
