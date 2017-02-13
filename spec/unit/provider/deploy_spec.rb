#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

describe Chef::Provider::Deploy do

  before do
    allow(ChefConfig).to receive(:windows?) { false }
    @release_time = Time.utc( 2004, 8, 15, 16, 23, 42)
    allow(Time).to receive(:now).and_return(@release_time)
    @expected_release_dir = "/my/deploy/dir/releases/20040815162342"
    @resource = Chef::Resource::Deploy.new("/my/deploy/dir")
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @provider = Chef::Provider::Deploy.new(@resource, @run_context)
    allow(@provider).to receive(:release_slug)
    allow(@provider).to receive(:release_path).and_return(@expected_release_dir)
  end

  it "loads scm resource" do
    expect(@provider.scm_provider).to receive(:load_current_resource)
    @provider.load_current_resource
  end

  it "supports :deploy and :rollback actions" do
    expect(@provider).to respond_to(:action_deploy)
    expect(@provider).to respond_to(:action_rollback)
  end

  context "when the deploy resource has a timeout attribute" do
    let(:ten_seconds) { 10 }
    before { @resource.timeout(ten_seconds) }
    it "relays the timeout to the scm resource" do
      expect(@provider.scm_provider.new_resource.timeout).to eq(ten_seconds)
    end
  end

  context "when the deploy resource has no timeout attribute" do
    it "should not set a timeout on the scm resource" do
      expect(@provider.scm_provider.new_resource.timeout).to be_nil
    end
  end

  context "when the deploy_to dir does not exist yet" do
    before do
      expect(FileUtils).to receive(:mkdir_p).with(@resource.deploy_to).ordered
      expect(FileUtils).to receive(:mkdir_p).with(@resource.shared_path).ordered
      allow(::File).to receive(:directory?).and_return(false)
      allow(@provider).to receive(:symlink)
      allow(@provider).to receive(:migrate)
      allow(@provider).to receive(:copy_cached_repo)
    end

    it "creates deploy_to dir" do
      expect(::Dir).to receive(:chdir).with(@expected_release_dir).exactly(4).times
      expect(@provider).to receive(:enforce_ownership).twice
      allow(@provider).to receive(:update_cached_repo)
      @provider.deploy
    end

  end

  it "does not create deploy_to dir if it exists" do
    allow(::File).to receive(:directory?).and_return(true)
    expect(::Dir).to receive(:chdir).with(@expected_release_dir).exactly(4).times
    expect(FileUtils).not_to receive(:mkdir_p).with(@resource.deploy_to)
    expect(FileUtils).not_to receive(:mkdir_p).with(@resource.shared_path)
    expect(@provider).to receive(:enforce_ownership).twice
    allow(@provider).to receive(:copy_cached_repo)
    allow(@provider).to receive(:update_cached_repo)
    allow(@provider).to receive(:symlink)
    allow(@provider).to receive(:migrate)
    @provider.deploy
  end

  it "ensures the deploy_to dir ownership after the verfication that it exists" do
    expect(::Dir).to receive(:chdir).with(@expected_release_dir).exactly(4).times
    expect(@provider).to receive(:verify_directories_exist).ordered
    expect(@provider).to receive(:enforce_ownership).ordered
    allow(@provider).to receive(:copy_cached_repo)
    allow(@provider).to receive(:update_cached_repo)
    allow(@provider).to receive(:install_gems)
    expect(@provider).to receive(:enforce_ownership).ordered
    allow(@provider).to receive(:enforce_ownership)
    allow(@provider).to receive(:symlink)
    allow(@provider).to receive(:migrate)
    @provider.deploy
  end

  it "updates and copies the repo, then does a migrate, symlink, restart, restart, cleanup on deploy" do
    allow(FileUtils).to receive(:mkdir_p).with("/my/deploy/dir")
    allow(FileUtils).to receive(:mkdir_p).with("/my/deploy/dir/shared")
    expect(@provider).to receive(:enforce_ownership).twice
    expect(@provider).to receive(:update_cached_repo)
    expect(@provider).to receive(:copy_cached_repo)
    expect(@provider).to receive(:install_gems)
    expect(@provider).to receive(:callback).with(:before_migrate, nil)
    expect(@provider).to receive(:migrate)
    expect(@provider).to receive(:callback).with(:before_symlink, nil)
    expect(@provider).to receive(:symlink)
    expect(@provider).to receive(:callback).with(:before_restart, nil)
    expect(@provider).to receive(:restart)
    expect(@provider).to receive(:callback).with(:after_restart, nil)
    expect(@provider).to receive(:cleanup!)
    @provider.deploy
  end

  it "should not deploy if there is already a deploy at release_path, and it is the current release" do
    allow(@provider).to receive(:all_releases).and_return([@expected_release_dir])
    allow(@provider).to receive(:current_release?).with(@expected_release_dir).and_return(true)
    expect(@provider).not_to receive(:deploy)
    @provider.run_action(:deploy)
  end

  it "should call action_rollback if there is already a deploy of this revision at release_path, and it is not the current release" do
    allow(@provider).to receive(:all_releases).and_return([@expected_release_dir, "102021"])
    allow(@provider).to receive(:current_release?).with(@expected_release_dir).and_return(false)
    expect(@provider).to receive(:rollback_to).with(@expected_release_dir)
    expect(@provider).to receive(:current_release?)
    @provider.run_action(:deploy)
  end

  it "calls deploy when deploying a new release" do
    allow(@provider).to receive(:all_releases).and_return([])
    expect(@provider).to receive(:deploy)
    @provider.run_action(:deploy)
  end

  it "runs action svn_force_export when new_resource.svn_force_export is true" do
    @resource.svn_force_export true
    expect(@provider.scm_provider).to receive(:run_action).with(:force_export)
    @provider.update_cached_repo
  end

  it "Removes the old release before deploying when force deploying over it" do
    allow(@provider).to receive(:all_releases).and_return([@expected_release_dir])
    expect(FileUtils).to receive(:rm_rf).with(@expected_release_dir)
    expect(@provider).to receive(:deploy)
    @provider.run_action(:force_deploy)
  end

  it "deploys as normal when force deploying and there's no prior release at the same path" do
    allow(@provider).to receive(:all_releases).and_return([])
    expect(@provider).to receive(:deploy)
    @provider.run_action(:force_deploy)
  end

  it "dont care by default if error happens on deploy" do
    allow(@provider).to receive(:all_releases).and_return(["previous_release"])
    allow(@provider).to receive(:deploy) { raise "Unexpected error" }
    allow(@provider).to receive(:previous_release_path).and_return("previous_release")
    expect(@provider).not_to receive(:rollback)
    expect do
      @provider.run_action(:deploy)
    end.to raise_exception(RuntimeError, "Unexpected error")
  end

  it "rollbacks to previous release if error happens on deploy" do
    @resource.rollback_on_error true
    allow(@provider).to receive(:all_releases).and_return(["previous_release"])
    allow(@provider).to receive(:deploy) { raise "Unexpected error" }
    allow(@provider).to receive(:previous_release_path).and_return("previous_release")
    expect(@provider).to receive(:rollback)
    expect do
      @provider.run_action(:deploy)
    end.to raise_exception(RuntimeError, "Unexpected error")
  end

  describe "on systems without broken Dir.glob results" do
    it "sets the release path to the penultimate release when one is not specified, symlinks, and rm's the last release on rollback" do
      allow(@provider).to receive(:release_path).and_return("/my/deploy/dir/releases/3")
      all_releases = ["/my/deploy/dir/releases/1", "/my/deploy/dir/releases/2", "/my/deploy/dir/releases/3", "/my/deploy/dir/releases/4", "/my/deploy/dir/releases/5"]
      allow(Dir).to receive(:glob).with("/my/deploy/dir/releases/*").and_return(all_releases)
      expect(@provider).to receive(:symlink)
      expect(FileUtils).to receive(:rm_rf).with("/my/deploy/dir/releases/4")
      expect(FileUtils).to receive(:rm_rf).with("/my/deploy/dir/releases/5")
      @provider.run_action(:rollback)
      expect(@provider.release_path).to eql("/my/deploy/dir/releases/3")
      expect(@provider.shared_path).to eql("/my/deploy/dir/shared")
    end

    it "sets the release path to the specified release, symlinks, and rm's any newer releases on rollback" do
      allow(@provider).to receive(:release_path).and_call_original
      all_releases = ["/my/deploy/dir/releases/20040815162342", "/my/deploy/dir/releases/20040700000000",
                      "/my/deploy/dir/releases/20040600000000", "/my/deploy/dir/releases/20040500000000"].sort!
      allow(Dir).to receive(:glob).with("/my/deploy/dir/releases/*").and_return(all_releases)
      expect(@provider).to receive(:symlink)
      expect(FileUtils).to receive(:rm_rf).with("/my/deploy/dir/releases/20040815162342")
      @provider.run_action(:rollback)
      expect(@provider.release_path).to eql("/my/deploy/dir/releases/20040700000000")
      expect(@provider.shared_path).to eql("/my/deploy/dir/shared")
    end

    it "sets the release path to the penultimate release, symlinks, and rm's the last release on rollback" do
      allow(@provider).to receive(:release_path).and_call_original
      all_releases = [ "/my/deploy/dir/releases/20040815162342",
                       "/my/deploy/dir/releases/20040700000000",
                       "/my/deploy/dir/releases/20040600000000",
                       "/my/deploy/dir/releases/20040500000000"]
      allow(Dir).to receive(:glob).with("/my/deploy/dir/releases/*").and_return(all_releases)
      expect(@provider).to receive(:symlink)
      expect(FileUtils).to receive(:rm_rf).with("/my/deploy/dir/releases/20040815162342")
      @provider.run_action(:rollback)
      expect(@provider.release_path).to eql("/my/deploy/dir/releases/20040700000000")
      expect(@provider.shared_path).to eql("/my/deploy/dir/shared")
    end

    describe "if there are no releases to fallback to" do

      it "an exception is raised when there is only 1 release" do
        #@provider.unstub(:release_path) -- unstub the release path on top to feed our own release path
        all_releases = [ "/my/deploy/dir/releases/20040815162342"]
        allow(Dir).to receive(:glob).with("/my/deploy/dir/releases/*").and_return(all_releases)
        #@provider.should_receive(:symlink)
        #FileUtils.should_receive(:rm_rf).with("/my/deploy/dir/releases/20040815162342")
        #@provider.run_action(:rollback)
        #@provider.release_path.should eql(NIL) -- no check needed since assertions will fail
        expect do
          @provider.run_action(:rollback)
        end.to raise_exception(RuntimeError, "There is no release to rollback to!")
      end

      it "an exception is raised when there are no releases" do
        all_releases = []
        allow(Dir).to receive(:glob).with("/my/deploy/dir/releases/*").and_return(all_releases)
        expect do
          @provider.run_action(:rollback)
        end.to raise_exception(RuntimeError, "There is no release to rollback to!")
      end
    end
  end

  describe "CHEF-628: on systems with broken Dir.glob results" do
    it "sets the release path to the penultimate release, symlinks, and rm's the last release on rollback" do
      allow(@provider).to receive(:release_path).and_call_original
      all_releases = [ "/my/deploy/dir/releases/20040500000000",
                       "/my/deploy/dir/releases/20040600000000",
                       "/my/deploy/dir/releases/20040700000000",
                       "/my/deploy/dir/releases/20040815162342" ]
      allow(Dir).to receive(:glob).with("/my/deploy/dir/releases/*").and_return(all_releases)
      expect(@provider).to receive(:symlink)
      expect(FileUtils).to receive(:rm_rf).with("/my/deploy/dir/releases/20040815162342")
      @provider.run_action(:rollback)
      expect(@provider.release_path).to eql("/my/deploy/dir/releases/20040700000000")
      expect(@provider.shared_path).to eql("/my/deploy/dir/shared")
    end
  end

  it "raises a runtime error when there's no release to rollback to" do
    all_releases = []
    allow(Dir).to receive(:glob).with("/my/deploy/dir/releases/*").and_return(all_releases)
    expect { @provider.run_action(:rollback) }.to raise_error(RuntimeError)
  end

  it "runs the new resource collection in the runner during a callback" do
    @runner = double("Runner")
    allow(Chef::Runner).to receive(:new).and_return(@runner)
    expect(@runner).to receive(:converge)
    callback_code = Proc.new { :noop }
    @provider.callback(:whatevs, callback_code)
  end

  it "loads callback files from the release/ dir if the file exists" do
    foo_callback = @expected_release_dir + "/deploy/foo.rb"
    expect(::File).to receive(:exist?).with(foo_callback).once.and_return(true)
    expect(::Dir).to receive(:chdir).with(@expected_release_dir).and_yield
    expect(@provider).to receive(:from_file).with(foo_callback)
    @provider.callback(:foo, "deploy/foo.rb")
  end

  it "raises a runtime error if a callback file is explicitly specified but does not exist" do
    baz_callback = "/deploy/baz.rb"
    expect(::File).to receive(:exist?).with("#{@expected_release_dir}/#{baz_callback}").and_return(false)
    @resource.before_migrate baz_callback
    @provider.define_resource_requirements
    @provider.action = :deploy
    expect { @provider.process_resource_requirements }.to raise_error(RuntimeError)
  end

  it "runs a default callback if the callback code is nil" do
    bar_callback = @expected_release_dir + "/deploy/bar.rb"
    expect(::File).to receive(:exist?).with(bar_callback).and_return(true)
    expect(::Dir).to receive(:chdir).with(@expected_release_dir).and_yield
    expect(@provider).to receive(:from_file).with(bar_callback)
    @provider.callback(:bar, nil)
  end

  it "skips an eval callback if the file doesn't exist" do
    barbaz_callback = @expected_release_dir + "/deploy/barbaz.rb"
    expect(::File).to receive(:exist?).with(barbaz_callback).and_return(false)
    expect(::Dir).to receive(:chdir).with(@expected_release_dir).and_yield
    expect(@provider).not_to receive(:from_file)
    @provider.callback(:barbaz, nil)
  end

  # CHEF-3449 #converge_by is called in #recipe_eval and must happen in sequence
  # with the other calls to #converge_by to keep the train on the tracks
  it "evaluates a callback file before the corresponding step" do
    expect(@provider).to receive(:verify_directories_exist)
    expect(@provider).to receive(:update_cached_repo)
    expect(@provider).to receive(:enforce_ownership)
    expect(@provider).to receive(:copy_cached_repo)
    expect(@provider).to receive(:install_gems)
    expect(@provider).to receive(:enforce_ownership)
    expect(@provider).to receive(:converge_by).ordered # before_migrate
    expect(@provider).to receive(:migrate).ordered
    expect(@provider).to receive(:converge_by).ordered # before_symlink
    expect(@provider).to receive(:symlink).ordered
    expect(@provider).to receive(:converge_by).ordered # before_restart
    expect(@provider).to receive(:restart).ordered
    expect(@provider).to receive(:converge_by).ordered # after_restart
    expect(@provider).to receive(:cleanup!)
    @provider.deploy
  end

  it "gets a SCM provider as specified by its resource" do
    expect(@provider.scm_provider).to be_an_instance_of(Chef::Provider::Git)
    expect(@provider.scm_provider.new_resource.destination).to eql("/my/deploy/dir/shared/cached-copy")
  end

  it "syncs the cached copy of the repo" do
    expect(@provider.scm_provider).to receive(:run_action).with(:sync)
    @provider.update_cached_repo
  end

  it "makes a copy of the cached repo in releases dir" do
    expect(FileUtils).to receive(:mkdir_p).with("/my/deploy/dir/releases")
    expect(FileUtils).to receive(:cp_r).with("/my/deploy/dir/shared/cached-copy/.", @expected_release_dir, :preserve => true)
    @provider.copy_cached_repo
  end

  it "calls the internal callback :release_created when cleaning up the releases" do
    allow(FileUtils).to receive(:mkdir_p)
    allow(FileUtils).to receive(:cp_r)
    expect(@provider).to receive(:release_created)
    @provider.cleanup!
  end

  it "chowns the whole release dir to user and group specified in the resource" do
    @resource.user "foo"
    @resource.group "bar"
    expect(FileUtils).to receive(:chown_R).with("foo", "bar", "/my/deploy/dir", { :force => true })
    @provider.enforce_ownership
  end

  it "skips the migration when resource.migrate => false but runs symlinks before migration" do
    @resource.migrate false
    expect(@provider).not_to receive :shell_out!
    expect(@provider).to receive :run_symlinks_before_migrate
    @provider.migrate
  end

  it "links the database.yml and runs resource.migration_command when resource.migrate #=> true" do
    @resource.migrate true
    @resource.migration_command "migration_foo"
    @resource.user "deployNinja"
    @resource.group "deployNinjas"
    @resource.environment "RAILS_ENV" => "production"
    expect(FileUtils).to receive(:ln_sf).with("/my/deploy/dir/shared/config/database.yml", @expected_release_dir + "/config/database.yml")
    expect(@provider).to receive(:enforce_ownership)

    allow(STDOUT).to receive(:tty?).and_return(true)
    allow(Chef::Log).to receive(:info?).and_return(true)
    expect(@provider).to receive(:shell_out!).with("migration_foo", :cwd => @expected_release_dir,
                                                                    :user => "deployNinja", :group => "deployNinjas",
                                                                    :log_level => :info, :live_stream => STDOUT,
                                                                    :log_tag => "deploy[/my/deploy/dir]",
                                                                    :environment => { "RAILS_ENV" => "production" })
    @provider.migrate
  end

  it "purges the current release's /log /tmp/pids/ and /public/system directories" do
    expect(FileUtils).to receive(:rm_rf).with(@expected_release_dir + "/log")
    expect(FileUtils).to receive(:rm_rf).with(@expected_release_dir + "/tmp/pids")
    expect(FileUtils).to receive(:rm_rf).with(@expected_release_dir + "/public/system")
    @provider.purge_tempfiles_from_current_release
  end

  it "symlinks temporary files and logs from the shared dir into the current release" do
    allow(FileUtils).to receive(:mkdir_p).with(@resource.shared_path + "/system")
    allow(FileUtils).to receive(:mkdir_p).with(@resource.shared_path + "/pids")
    allow(FileUtils).to receive(:mkdir_p).with(@resource.shared_path + "/log")
    expect(FileUtils).to receive(:mkdir_p).with(@expected_release_dir + "/tmp")
    expect(FileUtils).to receive(:mkdir_p).with(@expected_release_dir + "/public")
    expect(FileUtils).to receive(:mkdir_p).with(@expected_release_dir + "/config")
    expect(FileUtils).to receive(:ln_sf).with("/my/deploy/dir/shared/system", @expected_release_dir + "/public/system")
    expect(FileUtils).to receive(:ln_sf).with("/my/deploy/dir/shared/pids", @expected_release_dir + "/tmp/pids")
    expect(FileUtils).to receive(:ln_sf).with("/my/deploy/dir/shared/log", @expected_release_dir + "/log")
    expect(FileUtils).to receive(:ln_sf).with("/my/deploy/dir/shared/config/database.yml", @expected_release_dir + "/config/database.yml")
    expect(@provider).to receive(:enforce_ownership)
    @provider.link_tempfiles_to_current_release
  end

  it "symlinks the current release dir into production" do
    expect(FileUtils).to receive(:rm_f).with("/my/deploy/dir/current")
    expect(FileUtils).to receive(:ln_sf).with(@expected_release_dir, "/my/deploy/dir/current")
    expect(@provider).to receive(:enforce_ownership)
    @provider.link_current_release_to_production
  end

  context "with a customized app layout" do

    before do
      @resource.purge_before_symlink(%w{foo bar})
      @resource.create_dirs_before_symlink(%w{baz qux})
      @resource.symlinks "foo/bar" => "foo/bar", "baz" => "qux/baz"
      @resource.symlink_before_migrate "radiohead/in_rainbows.yml" => "awesome"
    end

    it "purges the purge_before_symlink directories" do
      expect(FileUtils).to receive(:rm_rf).with(@expected_release_dir + "/foo")
      expect(FileUtils).to receive(:rm_rf).with(@expected_release_dir + "/bar")
      @provider.purge_tempfiles_from_current_release
    end

    it "symlinks files from the shared directory to the current release directory" do
      expect(FileUtils).to receive(:mkdir_p).with(@expected_release_dir + "/baz")
      expect(FileUtils).to receive(:mkdir_p).with(@expected_release_dir + "/qux")
      allow(FileUtils).to receive(:mkdir_p).with(@resource.shared_path + "/foo/bar")
      allow(FileUtils).to receive(:mkdir_p).with(@resource.shared_path + "/baz")
      expect(FileUtils).to receive(:ln_sf).with("/my/deploy/dir/shared/foo/bar", @expected_release_dir + "/foo/bar")
      expect(FileUtils).to receive(:ln_sf).with("/my/deploy/dir/shared/baz", @expected_release_dir + "/qux/baz")
      expect(FileUtils).to receive(:ln_sf).with("/my/deploy/dir/shared/radiohead/in_rainbows.yml", @expected_release_dir + "/awesome")
      expect(@provider).to receive(:enforce_ownership)
      @provider.link_tempfiles_to_current_release
    end

  end

  it "does nothing for restart if restart_command is empty" do
    expect(@provider).not_to receive(:shell_out!)
    @provider.restart
  end

  it "runs the restart command in the current application dir when the resource has a restart_command" do
    @resource.restart_command "restartcmd"
    expect(@provider).to receive(:shell_out!).with("restartcmd", :cwd => "/my/deploy/dir/current", :log_tag => "deploy[/my/deploy/dir]", :log_level => :debug)
    @provider.restart
  end

  it "lists all available releases" do
    all_releases = ["/my/deploy/dir/20040815162342", "/my/deploy/dir/20040700000000",
                    "/my/deploy/dir/20040600000000", "/my/deploy/dir/20040500000000"].sort!
    expect(Dir).to receive(:glob).with("/my/deploy/dir/releases/*").and_return(all_releases)
    expect(@provider.all_releases).to eql(all_releases)
  end

  it "removes all but the 5 newest releases" do
    all_releases = ["/my/deploy/dir/20040815162342", "/my/deploy/dir/20040700000000",
                    "/my/deploy/dir/20040600000000", "/my/deploy/dir/20040500000000",
                    "/my/deploy/dir/20040400000000", "/my/deploy/dir/20040300000000",
                    "/my/deploy/dir/20040200000000", "/my/deploy/dir/20040100000000"].sort!
    allow(@provider).to receive(:all_releases).and_return(all_releases)
    expect(FileUtils).to receive(:rm_rf).with("/my/deploy/dir/20040100000000")
    expect(FileUtils).to receive(:rm_rf).with("/my/deploy/dir/20040200000000")
    expect(FileUtils).to receive(:rm_rf).with("/my/deploy/dir/20040300000000")
    @provider.cleanup!
  end

  it "removes all but a certain number of releases when the resource has a keep_releases" do
    @resource.keep_releases 7
    all_releases = ["/my/deploy/dir/20040815162342", "/my/deploy/dir/20040700000000",
                    "/my/deploy/dir/20040600000000", "/my/deploy/dir/20040500000000",
                    "/my/deploy/dir/20040400000000", "/my/deploy/dir/20040300000000",
                    "/my/deploy/dir/20040200000000", "/my/deploy/dir/20040100000000"].sort!
    allow(@provider).to receive(:all_releases).and_return(all_releases)
    expect(FileUtils).to receive(:rm_rf).with("/my/deploy/dir/20040100000000")
    @provider.cleanup!
  end

  it "fires a callback for :release_deleted when deleting an old release" do
    all_releases = ["/my/deploy/dir/20040815162342", "/my/deploy/dir/20040700000000",
                    "/my/deploy/dir/20040600000000", "/my/deploy/dir/20040500000000",
                    "/my/deploy/dir/20040400000000", "/my/deploy/dir/20040300000000"].sort!
    allow(@provider).to receive(:all_releases).and_return(all_releases)
    allow(FileUtils).to receive(:rm_rf)
    expect(@provider).to receive(:release_deleted).with("/my/deploy/dir/20040300000000")
    @provider.cleanup!
  end

  it "puts resource.to_hash in @configuration for backwards compat with capistano-esque deploy hooks" do
    expect(@provider.instance_variable_get(:@configuration)).to eq(@resource.to_hash)
  end

  it "sets @configuration[:environment] to the value of RAILS_ENV for backwards compat reasons" do
    resource = Chef::Resource::Deploy.new("/my/deploy/dir")
    resource.environment "production"
    provider = Chef::Provider::Deploy.new(resource, @run_context)
    expect(provider.instance_variable_get(:@configuration)[:environment]).to eql("production")
  end

  it "shouldn't give a no method error on migrate if the environment is nil" do
    allow(@provider).to receive(:enforce_ownership)
    allow(@provider).to receive(:run_symlinks_before_migrate)
    allow(@provider).to receive(:shell_out!)
    @provider.migrate

  end

  context "using inline recipes for callbacks" do

    it "runs an inline recipe with the provided block for :callback_name == {:recipe => &block} " do
      snitch = nil
      recipe_code = Proc.new { snitch = 42 }
      #@provider.should_receive(:instance_eval).with(&recipe_code)
      @provider.callback(:whateverz, recipe_code)
      expect(snitch).to eq(42)
    end

    it "loads a recipe file from the specified path and from_file evals it" do
      expect(::File).to receive(:exist?).with(@expected_release_dir + "/chefz/foobar_callback.rb").once.and_return(true)
      expect(::Dir).to receive(:chdir).with(@expected_release_dir).and_yield
      expect(@provider).to receive(:from_file).with(@expected_release_dir + "/chefz/foobar_callback.rb")
      @provider.callback(:whateverz, "chefz/foobar_callback.rb")
    end

    it "instance_evals a block/proc for restart command" do
      snitch = nil
      restart_cmd = Proc.new { snitch = 42 }
      @resource.restart(&restart_cmd)
      @provider.restart
      expect(snitch).to eq(42)
    end

  end

  describe "API bridge to capistrano" do
    it "defines sudo as a forwarder to execute" do
      expect(@provider).to receive(:execute).with("the moon, fool")
      @provider.sudo("the moon, fool")
    end

    it "defines run as a forwarder to execute, setting the user, group, cwd and environment to new_resource.user" do
      mock_execution = double("Resource::Execute")
      expect(@provider).to receive(:execute).with("iGoToHell4this").and_return(mock_execution)
      @resource.user("notCoolMan")
      @resource.group("Ggroup")
      @resource.environment("APP_ENV" => "staging")
      @resource.deploy_to("/my/app")
      expect(mock_execution).to receive(:user).with("notCoolMan")
      expect(mock_execution).to receive(:group).with("Ggroup")
      expect(mock_execution).to receive(:cwd) { |*args|
        if args.empty?
          nil
        else
          expect(args.size).to eq(1)
          expect(args.first).to eq(@provider.release_path)
        end
      }.twice
      expect(mock_execution).to receive(:environment) { |*args|
        if args.empty?
          nil
        else
          expect(args.size).to eq(1)
          expect(args.first).to eq({ "APP_ENV" => "staging" })
        end
      }.twice
      @provider.run("iGoToHell4this")

    end

    it "defines run as a forwarder to execute, setting cwd and environment but not override" do
      mock_execution = double("Resource::Execute")
      expect(@provider).to receive(:execute).with("iGoToHell4this").and_return(mock_execution)
      @resource.user("notCoolMan")
      expect(mock_execution).to receive(:user).with("notCoolMan")
      expect(mock_execution).to receive(:cwd).with(no_args()).and_return("/some/value")
      expect(mock_execution).to receive(:environment).with(no_args()).and_return({})
      @provider.run("iGoToHell4this")
    end

    it "converts sudo and run to exec resources in hooks" do
      runner = double("tehRunner")
      allow(Chef::Runner).to receive(:new).and_return(runner)

      snitch = nil
      @resource.user("tehCat")

      callback_code = Proc.new do
        snitch = 42
        temp_collection = resource_collection
        run("tehMice")
        snitch = temp_collection.lookup("execute[tehMice]")
      end

      expect(runner).to receive(:converge)
      #
      @provider.callback(:phony, callback_code)
      expect(snitch).to be_an_instance_of(Chef::Resource::Execute)
      expect(snitch.user).to eq("tehCat")
    end
  end

  describe "installing gems from a gems.yml" do

    before do
      allow(::File).to receive(:exist?).with("#{@expected_release_dir}/gems.yml").and_return(true)
      @gem_list = [{ :name => "eventmachine", :version => "0.12.9" }]
    end

    it "reads a gems.yml file, creating gem providers for each with action :upgrade" do
      expect(IO).to receive(:read).with("#{@expected_release_dir}/gems.yml").and_return("cookie")
      expect(YAML).to receive(:load).with("cookie").and_return(@gem_list)

      gems = @provider.send(:gem_packages)

      expect(gems.map { |g| g.action }).to eq([%i{install}])
      expect(gems.map { |g| g.name }).to eq(%w{eventmachine})
      expect(gems.map { |g| g.version }).to eq(%w{0.12.9})
    end

    it "takes a list of gem providers converges them" do
      allow(IO).to receive(:read)
      allow(YAML).to receive(:load).and_return(@gem_list)
      expected_gem_resources = @provider.send(:gem_packages).map { |r| [r.name, r.version] }
      gem_runner = @provider.send(:gem_resource_collection_runner)
      # no one has heard of defining == to be meaningful so I have use this monstrosity
      actual = gem_runner.run_context.resource_collection.all_resources.map { |r| [r.name, r.version] }
      expect(actual).to eq(expected_gem_resources)
    end

  end

end
