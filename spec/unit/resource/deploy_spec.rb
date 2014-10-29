#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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
require 'support/shared/unit/resource/static_provider_resolution'

describe Chef::Resource::Deploy do

  static_provider_resolution(
    resource: Chef::Resource::Deploy,
    provider: Chef::Provider::Deploy::Timestamped,
    name: :deploy,
    action: :deploy,
  )


  class << self
    def resource_has_a_string_attribute(attr_name)
      it "has a String attribute for #{attr_name.to_s}" do
        @resource.send(attr_name, "this is a string")
        expect(@resource.send(attr_name)).to eql("this is a string")
        expect {@resource.send(attr_name, 8675309)}.to raise_error(ArgumentError)
      end
    end

    def resource_has_a_boolean_attribute(attr_name, opts={:defaults_to=>false})
      it "has a Boolean attribute for #{attr_name.to_s}" do
        expect(@resource.send(attr_name)).to eql(opts[:defaults_to])
        @resource.send(attr_name, !opts[:defaults_to])
        expect(@resource.send(attr_name)).to eql( !opts[:defaults_to] )
      end
    end

    def resource_has_a_callback_attribute(attr_name)
      it "has a Callback attribute #{attr_name}" do
        callback_block = lambda { :noop }
        expect {@resource.send(attr_name, &callback_block)}.not_to raise_error
        expect(@resource.send(attr_name)).to eq(callback_block)
        callback_file = "path/to/callback.rb"
        expect {@resource.send(attr_name, callback_file)}.not_to raise_error
        expect(@resource.send(attr_name)).to eq(callback_file)
        expect {@resource.send(attr_name, :this_is_fail)}.to raise_error(ArgumentError)
      end
    end
  end

  before do
    @resource = Chef::Resource::Deploy.new("/my/deploy/dir")
  end

  resource_has_a_string_attribute(:repo)
  resource_has_a_string_attribute(:deploy_to)
  resource_has_a_string_attribute(:role)
  resource_has_a_string_attribute(:restart_command)
  resource_has_a_string_attribute(:migration_command)
  resource_has_a_string_attribute(:user)
  resource_has_a_string_attribute(:group)
  resource_has_a_string_attribute(:repository_cache)
  resource_has_a_string_attribute(:copy_exclude)
  resource_has_a_string_attribute(:revision)
  resource_has_a_string_attribute(:remote)
  resource_has_a_string_attribute(:git_ssh_wrapper)
  resource_has_a_string_attribute(:svn_username)
  resource_has_a_string_attribute(:svn_password)
  resource_has_a_string_attribute(:svn_arguments)
  resource_has_a_string_attribute(:svn_info_args)

  resource_has_a_boolean_attribute(:migrate, :defaults_to=>false)
  resource_has_a_boolean_attribute(:enable_submodules, :defaults_to=>false)
  resource_has_a_boolean_attribute(:shallow_clone, :defaults_to=>false)

  it "uses the first argument as the deploy directory" do
    expect(@resource.deploy_to).to eql("/my/deploy/dir")
  end

  # For git, any revision, branch, tag, whatever is resolved to a SHA1 ref.
  # For svn, the branch is included in the repo URL.
  # Therefore, revision and branch ARE NOT SEPARATE THINGS
  it "aliases #revision as #branch" do
    @resource.branch "stable"
    expect(@resource.revision).to eql("stable")
  end

  it "takes the SCM resource to use as a constant, and defaults to git" do
    expect(@resource.scm_provider).to eql(Chef::Provider::Git)
    @resource.scm_provider Chef::Provider::Subversion
    expect(@resource.scm_provider).to eql(Chef::Provider::Subversion)
  end

  it "allows scm providers to be set via symbol" do
    expect(@resource.scm_provider).to eq(Chef::Provider::Git)
    @resource.scm_provider :subversion
    expect(@resource.scm_provider).to eq(Chef::Provider::Subversion)
  end

  it "allows scm providers to be set via string" do
    expect(@resource.scm_provider).to eq(Chef::Provider::Git)
    @resource.scm_provider "subversion"
    expect(@resource.scm_provider).to eq(Chef::Provider::Subversion)
  end

  it "has a boolean attribute for svn_force_export defaulting to false" do
    expect(@resource.svn_force_export).to be_falsey
    @resource.svn_force_export true
    expect(@resource.svn_force_export).to be_truthy
    expect {@resource.svn_force_export(10053)}.to raise_error(ArgumentError)
  end

  it "takes arbitrary environment variables in a hash" do
    @resource.environment "RAILS_ENV" => "production"
    expect(@resource.environment).to eq({"RAILS_ENV" => "production"})
  end

  it "takes string arguments to environment for backwards compat, setting RAILS_ENV, RACK_ENV, and MERB_ENV" do
    @resource.environment "production"
    expect(@resource.environment).to eq({"RAILS_ENV"=>"production", "RACK_ENV"=>"production","MERB_ENV"=>"production"})
  end

  it "sets destination to $deploy_to/shared/$repository_cache" do
    expect(@resource.destination).to eql("/my/deploy/dir/shared/cached-copy")
  end

  it "sets shared_path to $deploy_to/shared" do
    expect(@resource.shared_path).to eql("/my/deploy/dir/shared")
  end

  it "sets current_path to $deploy_to/current" do
    expect(@resource.current_path).to eql("/my/deploy/dir/current")
  end

  it "gets the current_path correct even if the shared_path is set (regression test)" do
    @resource.shared_path
    expect(@resource.current_path).to eql("/my/deploy/dir/current")
  end

  it "gives #depth as 5 if shallow clone is true, nil otherwise" do
    expect(@resource.depth).to be_nil
    @resource.shallow_clone true
    expect(@resource.depth).to eql("5")
  end

  it "aliases repo as repository" do
    @resource.repository "git@github.com/opcode/cookbooks.git"
    expect(@resource.repo).to eql("git@github.com/opcode/cookbooks.git")
  end

  it "aliases git_ssh_wrapper as ssh_wrapper" do
    @resource.ssh_wrapper "git_my_repo.sh"
    expect(@resource.git_ssh_wrapper).to eql("git_my_repo.sh")
  end

  it "has an Array attribute purge_before_symlink, default: log, tmp/pids, public/system" do
    expect(@resource.purge_before_symlink).to eq(%w{ log tmp/pids public/system })
    @resource.purge_before_symlink %w{foo bar baz}
    expect(@resource.purge_before_symlink).to eq(%w{foo bar baz})
  end

  it "has an Array attribute create_dirs_before_symlink, default: tmp, public, config" do
    expect(@resource.create_dirs_before_symlink).to eq(%w{tmp public config})
    @resource.create_dirs_before_symlink %w{foo bar baz}
    expect(@resource.create_dirs_before_symlink).to eq(%w{foo bar baz})
  end

  it 'has a Hash attribute symlinks, default: {"system" => "public/system", "pids" => "tmp/pids", "log" => "log"}' do
    default = { "system" => "public/system", "pids" => "tmp/pids", "log" => "log"}
    expect(@resource.symlinks).to eq(default)
    @resource.symlinks "foo" => "bar/baz"
    expect(@resource.symlinks).to eq({"foo" => "bar/baz"})
  end

  it 'has a Hash attribute symlink_before_migrate, default "config/database.yml" => "config/database.yml"' do
    expect(@resource.symlink_before_migrate).to eq({"config/database.yml" => "config/database.yml"})
    @resource.symlink_before_migrate "wtf?" => "wtf is going on"
    expect(@resource.symlink_before_migrate).to eq({"wtf?" => "wtf is going on"})
  end

  resource_has_a_callback_attribute :before_migrate
  resource_has_a_callback_attribute :before_symlink
  resource_has_a_callback_attribute :before_restart
  resource_has_a_callback_attribute :after_restart

  it "aliases restart_command as restart" do
    @resource.restart "foobaz"
    expect(@resource.restart_command).to eq("foobaz")
  end

  it "takes a block for the restart parameter" do
    restart_like_this = lambda {p :noop}
    @resource.restart(&restart_like_this)
    expect(@resource.restart).to eq(restart_like_this)
  end

  it "allows providers to be set with a full class name" do
    @resource.provider Chef::Provider::Deploy::Timestamped
    expect(@resource.provider).to eq(Chef::Provider::Deploy::Timestamped)
  end

  it "allows deploy providers to be set via symbol" do
    @resource.provider :revision
    expect(@resource.provider).to eq(Chef::Provider::Deploy::Revision)
  end

  it "allows deploy providers to be set via string" do
    @resource.provider "revision"
    expect(@resource.provider).to eq(Chef::Provider::Deploy::Revision)
  end

  it "defaults keep_releases to 5" do
    expect(@resource.keep_releases).to eq(5)
  end

  it "allows keep_releases to be set via integer" do
    @resource.keep_releases 10
    expect(@resource.keep_releases).to eq(10)
  end

  it "enforces a minimum keep_releases of 1" do
    @resource.keep_releases 0
    expect(@resource.keep_releases).to eq(1)
  end

  describe "when it has a timeout attribute" do
    let(:ten_seconds) { 10 }
    before { @resource.timeout(ten_seconds) }
    it "stores this timeout" do
      expect(@resource.timeout).to eq(ten_seconds)
    end
  end

  describe "when it has no timeout attribute" do
    it "should have no default timeout" do
      expect(@resource.timeout).to be_nil
    end
  end

  describe "when it has meta application root, revision, user, group,
            scm provider, repository cache, environment, simlinks and migrate" do
    before do
      @resource.repository("http://uri.org")
      @resource.deploy_to("/")
      @resource.revision("1.2.3")
      @resource.user("root")
      @resource.group("pokemon")
      @resource.scm_provider(Chef::Provider::Git)
      @resource.repository_cache("cached-copy")
      @resource.environment({"SUDO" => "TRUE"})
      @resource.symlinks({"system" => "public/system"})
      @resource.migrate(false)

    end

    it "describes its state" do
      state = @resource.state
      expect(state[:deploy_to]).to eq("/")
      expect(state[:revision]).to eq("1.2.3")
    end

    it "returns the repository URI as its identity" do
      expect(@resource.identity).to eq("http://uri.org")
    end
  end

end
