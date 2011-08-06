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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Provider::Deploy do

  before do
    @release_time = Time.utc( 2004, 8, 15, 16, 23, 42)
    Time.stub!(:now).and_return(@release_time)
    @expected_release_dir = "/my/deploy/dir/releases/20040815162342"
    @resource = Chef::Resource::Deploy.new("/my/deploy/dir")
    @node = Chef::Node.new
    @run_context = Chef::RunContext.new(@node, {})
    @provider = Chef::Provider::Deploy.new(@resource, @run_context)
    @provider.stub!(:release_slug)
    @provider.stub!(:release_path).and_return(@expected_release_dir)
  end

  it "supports :deploy and :rollback actions" do
    @provider.should respond_to(:action_deploy)
    @provider.should respond_to(:action_rollback)
  end

  it "creates deploy_to dir if it does not exist yet" do
    FileUtils.should_receive(:mkdir_p).with(@resource.deploy_to)
    FileUtils.should_receive(:mkdir_p).with(@resource.shared_path)
    @provider.stub(:copy_cached_repo)
    @provider.stub(:update_cached_repo)
    @provider.stub(:symlink)
    @provider.stub(:migrate)
    @provider.deploy
  end

  it "updates and copies the repo, then does a migrate, symlink, restart, restart, cleanup on deploy" do
    FileUtils.stub(:mkdir_p).with("/my/deploy/dir")
    FileUtils.stub(:mkdir_p).with("/my/deploy/dir/shared")
    @provider.should_receive(:enforce_ownership).twice
    @provider.should_receive(:update_cached_repo)
    @provider.should_receive(:copy_cached_repo)
    @provider.should_receive(:install_gems)
    @provider.should_receive(:callback).with(:before_migrate, nil)
    @provider.should_receive(:migrate)
    @provider.should_receive(:callback).with(:before_symlink, nil)
    @provider.should_receive(:symlink)
    @provider.should_receive(:callback).with(:before_restart, nil)
    @provider.should_receive(:restart)
    @provider.should_receive(:callback).with(:after_restart, nil)
    @provider.should_receive(:cleanup!)
    @provider.deploy
  end

  it "should not deploy if there is already a deploy at release_path, and it is the current release" do
    @provider.stub!(:all_releases).and_return([@expected_release_dir])
    @provider.should_not_receive(:deploy)
    @provider.action_deploy
  end

  it "should call action_rollback if there is already a deploy of this revision at release_path, and it is not the current release" do
    @provider.stub!(:all_releases).and_return([@expected_release_dir, "102021"])
    @provider.should_receive(:action_rollback)
    @provider.action_deploy
  end

  it "calls deploy when deploying a new release" do
    @provider.stub!(:all_releases).and_return([])
    @provider.should_receive(:deploy)
    @provider.action_deploy
  end

  it "runs action svn_force_export when new_resource.svn_force_export is true" do
    @resource.svn_force_export true
    @provider.scm_provider.should_receive(:action_force_export)
    @provider.svn_force_export
  end

  it "Removes the old release before deploying when force deploying over it" do
    @provider.stub!(:all_releases).and_return([@expected_release_dir])
    FileUtils.should_receive(:rm_rf).with(@expected_release_dir)
    @provider.should_receive(:deploy)
    @provider.action_force_deploy
  end

  it "deploys as normal when force deploying and there's no prior release at the same path" do
    @provider.stub!(:all_releases).and_return([])
    @provider.should_receive(:deploy)
    @provider.action_force_deploy
  end


  describe "on systems without broken Dir.glob results" do
    it "sets the release path to the penultimate release when one is not specified, symlinks, and rm's the last release on rollback" do
      @provider.stub!(:release_path).and_return("/my/deploy/dir/releases/3")
      all_releases = ["/my/deploy/dir/releases/1", "/my/deploy/dir/releases/2", "/my/deploy/dir/releases/3", "/my/deploy/dir/releases/4", "/my/deploy/dir/releases/5"]
      Dir.stub!(:glob).with("/my/deploy/dir/releases/*").and_return(all_releases)
      @provider.should_receive(:symlink)
      FileUtils.should_receive(:rm_rf).with("/my/deploy/dir/releases/4")
      FileUtils.should_receive(:rm_rf).with("/my/deploy/dir/releases/5")
      @provider.action_rollback
      @provider.release_path.should eql("/my/deploy/dir/releases/3")
    end

    it "sets the release path to the specified release, symlinks, and rm's any newer releases on rollback" do
      @provider.unstub!(:release_path)
      all_releases = ["/my/deploy/dir/releases/20040815162342", "/my/deploy/dir/releases/20040700000000",
                      "/my/deploy/dir/releases/20040600000000", "/my/deploy/dir/releases/20040500000000"].sort!
      Dir.stub!(:glob).with("/my/deploy/dir/releases/*").and_return(all_releases)
      @provider.should_receive(:symlink)
      FileUtils.should_receive(:rm_rf).with("/my/deploy/dir/releases/20040815162342")
      @provider.action_rollback
      @provider.release_path.should eql("/my/deploy/dir/releases/20040700000000")
    end

    it "sets the release path to the penultimate release, symlinks, and rm's the last release on rollback" do
      @provider.unstub!(:release_path)
      all_releases = [ "/my/deploy/dir/releases/20040815162342",
                       "/my/deploy/dir/releases/20040700000000",
                       "/my/deploy/dir/releases/20040600000000",
                       "/my/deploy/dir/releases/20040500000000"]
      Dir.stub!(:glob).with("/my/deploy/dir/releases/*").and_return(all_releases)
      @provider.should_receive(:symlink)
      FileUtils.should_receive(:rm_rf).with("/my/deploy/dir/releases/20040815162342")
      @provider.action_rollback
      @provider.release_path.should eql("/my/deploy/dir/releases/20040700000000")
    end
  end

  describe "CHEF-628: on systems with broken Dir.glob results" do
    it "sets the release path to the penultimate release, symlinks, and rm's the last release on rollback" do
      @provider.unstub!(:release_path)
      all_releases = [ "/my/deploy/dir/releases/20040500000000",
                       "/my/deploy/dir/releases/20040600000000",
                       "/my/deploy/dir/releases/20040700000000",
                       "/my/deploy/dir/releases/20040815162342" ]
      Dir.stub!(:glob).with("/my/deploy/dir/releases/*").and_return(all_releases)
      @provider.should_receive(:symlink)
      FileUtils.should_receive(:rm_rf).with("/my/deploy/dir/releases/20040815162342")
      @provider.action_rollback
      @provider.release_path.should eql("/my/deploy/dir/releases/20040700000000")
    end
  end

  it "raises a runtime error when there's no release to rollback to" do
    all_releases = []
    Dir.stub!(:glob).with("/my/deploy/dir/releases/*").and_return(all_releases)
    lambda {@provider.action_rollback}.should raise_error(RuntimeError)
  end

  it "runs the new resource collection in the runner during a callback" do
    @runner = mock("Runner")
    Chef::Runner.stub!(:new).and_return(@runner)
    @runner.should_receive(:converge)
    callback_code = Proc.new { :noop }
    @provider.callback(:whatevs, callback_code)
  end

  it "loads callback files from the release/ dir if the file exists" do
    foo_callback = @expected_release_dir + "/deploy/foo.rb"
    ::File.should_receive(:exist?).with(foo_callback).twice.and_return(true)
    ::Dir.should_receive(:chdir).with(@expected_release_dir).and_yield
    @provider.should_receive(:from_file).with(foo_callback)
    @provider.callback(:foo, "deploy/foo.rb")
  end

  it "raises a runtime error if a callback file is explicitly specified but does not exist" do
    baz_callback = @expected_release_dir + "/deploy/baz.rb"
    ::File.should_receive(:exist?).with(baz_callback).and_return(false)
    lambda {@provider.callback(:foo, "deploy/baz.rb")}.should raise_error(RuntimeError)
  end

  it "runs a default callback if the callback code is nil" do
    bar_callback = @expected_release_dir + "/deploy/bar.rb"
    ::File.should_receive(:exist?).with(bar_callback).and_return(true)
    ::Dir.should_receive(:chdir).with(@expected_release_dir).and_yield
    @provider.should_receive(:from_file).with(bar_callback)
    @provider.callback(:bar, nil)
  end

  it "skips an eval callback if the file doesn't exist" do
    barbaz_callback = @expected_release_dir + "/deploy/barbaz.rb"
    ::File.should_receive(:exist?).with(barbaz_callback).and_return(false)
    @provider.should_not_receive(:from_file)
    @provider.callback(:barbaz, nil)
  end

  it "gets a SCM provider as specified by its resource" do
    @provider.scm_provider.should be_an_instance_of(Chef::Provider::Git)
    @provider.scm_provider.new_resource.destination.should eql("/my/deploy/dir/shared/cached-copy")
  end

  it "syncs the cached copy of the repo" do
    @provider.scm_provider.should_receive(:load_current_resource)
    @provider.scm_provider.should_receive(:action_sync)
    @provider.update_cached_repo
  end

  it "makes a copy of the cached repo in releases dir" do
    FileUtils.should_receive(:mkdir_p).with("/my/deploy/dir/releases")
    @provider.should_receive(:run_command).with({:command => "cp -RPp /my/deploy/dir/shared/cached-copy/. #{@expected_release_dir}"})
    @provider.copy_cached_repo
  end

  it "calls the internal callback :release_created when copying the cached repo" do
    FileUtils.stub!(:mkdir_p)
    @provider.stub!(:run_command).and_return(true)
    @provider.should_receive(:release_created)
    @provider.copy_cached_repo
  end

  it "chowns the whole release dir to user and group specified in the resource" do
    @resource.user "foo"
    @resource.group "bar"
    FileUtils.should_receive(:chown_R).with("foo", "bar", "/my/deploy/dir")
    @provider.enforce_ownership
  end

  it "skips the migration when resource.migrate => false but runs symlinks before migration" do
    @resource.migrate false
    @provider.should_not_receive :run_command
    @provider.should_receive :run_symlinks_before_migrate
    @provider.migrate
  end

  it "links the database.yml and runs resource.migration_command when resource.migrate #=> true" do
    @resource.migrate true
    @resource.migration_command "migration_foo"
    @resource.user "deployNinja"
    @resource.group "deployNinjas"
    @resource.environment "RAILS_ENV" => "production"
    FileUtils.should_receive(:ln_sf).with("/my/deploy/dir/shared/config/database.yml", @expected_release_dir + "/config/database.yml")
    @provider.should_receive(:enforce_ownership)
    @provider.should_receive(:run_command).with(:command => "migration_foo", :cwd => @expected_release_dir,
                                                :user => "deployNinja", :group => "deployNinjas",
																								:command_log_level => :info, :live_stream => STDOUT,
																								:command_log_prepend => "deploy[/my/deploy/dir]",
                                                :environment => {"RAILS_ENV"=>"production"})
    @provider.migrate
  end

  it "purges the current release's /log /tmp/pids/ and /public/system directories" do
    FileUtils.should_receive(:rm_rf).with(@expected_release_dir + "/log")
    FileUtils.should_receive(:rm_rf).with(@expected_release_dir + "/tmp/pids")
    FileUtils.should_receive(:rm_rf).with(@expected_release_dir + "/public/system")
    @provider.purge_tempfiles_from_current_release
  end

  it "symlinks temporary files and logs from the shared dir into the current release" do
    FileUtils.stub(:mkdir_p).with(@resource.shared_path + "/system")
    FileUtils.stub(:mkdir_p).with(@resource.shared_path + "/pids")
    FileUtils.stub(:mkdir_p).with(@resource.shared_path + "/log")
    FileUtils.should_receive(:mkdir_p).with(@expected_release_dir + "/tmp")
    FileUtils.should_receive(:mkdir_p).with(@expected_release_dir + "/public")
    FileUtils.should_receive(:mkdir_p).with(@expected_release_dir + "/config")
    FileUtils.should_receive(:ln_sf).with("/my/deploy/dir/shared/system", @expected_release_dir + "/public/system")
    FileUtils.should_receive(:ln_sf).with("/my/deploy/dir/shared/pids", @expected_release_dir + "/tmp/pids")
    FileUtils.should_receive(:ln_sf).with("/my/deploy/dir/shared/log", @expected_release_dir + "/log")
    FileUtils.should_receive(:ln_sf).with("/my/deploy/dir/shared/config/database.yml", @expected_release_dir + "/config/database.yml")
    @provider.should_receive(:enforce_ownership)
    @provider.link_tempfiles_to_current_release
  end

  it "symlinks the current release dir into production" do
    FileUtils.should_receive(:rm_f).with("/my/deploy/dir/current")
    FileUtils.should_receive(:ln_sf).with(@expected_release_dir, "/my/deploy/dir/current")
    @provider.should_receive(:enforce_ownership)
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
      FileUtils.should_receive(:rm_rf).with(@expected_release_dir + "/foo")
      FileUtils.should_receive(:rm_rf).with(@expected_release_dir + "/bar")
      @provider.purge_tempfiles_from_current_release
    end

    it "symlinks files from the shared directory to the current release directory" do
      FileUtils.should_receive(:mkdir_p).with(@expected_release_dir + "/baz")
      FileUtils.should_receive(:mkdir_p).with(@expected_release_dir + "/qux")
      FileUtils.stub(:mkdir_p).with(@resource.shared_path + "/foo/bar")
      FileUtils.stub(:mkdir_p).with(@resource.shared_path + "/baz")
      FileUtils.should_receive(:ln_sf).with("/my/deploy/dir/shared/foo/bar", @expected_release_dir + "/foo/bar")
      FileUtils.should_receive(:ln_sf).with("/my/deploy/dir/shared/baz", @expected_release_dir + "/qux/baz")
      FileUtils.should_receive(:ln_sf).with("/my/deploy/dir/shared/radiohead/in_rainbows.yml", @expected_release_dir + "/awesome")
      @provider.should_receive(:enforce_ownership)
      @provider.link_tempfiles_to_current_release
    end
    
  end

  it "does nothing for restart if restart_command is empty" do
    @provider.should_not_receive(:run_command)
    @provider.restart
  end

  it "runs the restart command in the current application dir when the resource has a restart_command" do
    @resource.restart_command "restartcmd"
    @provider.should_receive(:run_command).with(:command => "restartcmd", :cwd => "/my/deploy/dir/current", :command_log_prepend => "deploy[/my/deploy/dir]", :command_log_level => :debug)
    @provider.restart
  end

  it "lists all available releases" do
    all_releases = ["/my/deploy/dir/20040815162342", "/my/deploy/dir/20040700000000",
                    "/my/deploy/dir/20040600000000", "/my/deploy/dir/20040500000000"].sort!
    Dir.should_receive(:glob).with("/my/deploy/dir/releases/*").and_return(all_releases)
    @provider.all_releases.should eql(all_releases)
  end

  it "removes all but the 5 newest releases" do
    all_releases = ["/my/deploy/dir/20040815162342", "/my/deploy/dir/20040700000000",
                    "/my/deploy/dir/20040600000000", "/my/deploy/dir/20040500000000",
                    "/my/deploy/dir/20040400000000", "/my/deploy/dir/20040300000000",
                    "/my/deploy/dir/20040200000000", "/my/deploy/dir/20040100000000"].sort!
    @provider.stub!(:all_releases).and_return(all_releases)
    FileUtils.should_receive(:rm_rf).with("/my/deploy/dir/20040100000000")
    FileUtils.should_receive(:rm_rf).with("/my/deploy/dir/20040200000000")
    FileUtils.should_receive(:rm_rf).with("/my/deploy/dir/20040300000000")
    @provider.cleanup!
  end

  it "fires a callback for :release_deleted when deleting an old release" do
    all_releases = ["/my/deploy/dir/20040815162342", "/my/deploy/dir/20040700000000",
                    "/my/deploy/dir/20040600000000", "/my/deploy/dir/20040500000000",
                    "/my/deploy/dir/20040400000000", "/my/deploy/dir/20040300000000"].sort!
    @provider.stub!(:all_releases).and_return(all_releases)
    FileUtils.stub!(:rm_rf)
    @provider.should_receive(:release_deleted).with("/my/deploy/dir/20040300000000")
    @provider.cleanup!
  end

  it "puts resource.to_hash in @configuration for backwards compat with capistano-esque deploy hooks" do
    @provider.instance_variable_get(:@configuration).should == @resource.to_hash
  end

  it "sets @configuration[:environment] to the value of RAILS_ENV for backwards compat reasons" do
    resource = Chef::Resource::Deploy.new("/my/deploy/dir")
    resource.environment "production"
    provider = Chef::Provider::Deploy.new(resource, @run_context)
    provider.instance_variable_get(:@configuration)[:environment].should eql("production")
  end

  it "shouldn't give a no method error on migrate if the environment is nil" do
    @provider.stub!(:enforce_ownership)
    @provider.stub!(:run_symlinks_before_migrate)
    @provider.stub!(:run_command)
    @provider.migrate
  end

  context "using inline recipes for callbacks" do

    it "runs an inline recipe with the provided block for :callback_name == {:recipe => &block} " do
      snitch = nil
      recipe_code = Proc.new {snitch = 42}
      #@provider.should_receive(:instance_eval).with(&recipe_code)
      @provider.callback(:whateverz, recipe_code)
      snitch.should == 42
    end

    it "loads a recipe file from the specified path and from_file evals it" do
      ::File.should_receive(:exist?).with(@expected_release_dir + "/chefz/foobar_callback.rb").twice.and_return(true)
      ::Dir.should_receive(:chdir).with(@expected_release_dir).and_yield
      @provider.should_receive(:from_file).with(@expected_release_dir + "/chefz/foobar_callback.rb")
      @provider.callback(:whateverz, "chefz/foobar_callback.rb")
    end

    it "instance_evals a block/proc for restart command" do
      snitch = nil
      restart_cmd = Proc.new {snitch = 42}
      @resource.restart(&restart_cmd)
      @provider.restart
      snitch.should == 42
    end

  end

  describe "API bridge to capistrano" do
    it "defines sudo as a forwarder to execute" do
      @provider.should_receive(:execute).with("the moon, fool")
      @provider.sudo("the moon, fool")
    end

    it "defines run as a forwarder to execute, setting the user, group, cwd and environment to new_resource.user" do
      mock_execution = mock("Resource::Execute")
      @provider.should_receive(:execute).with("iGoToHell4this").and_return(mock_execution)
      @resource.user("notCoolMan")
      @resource.group("Ggroup")
      @resource.environment("APP_ENV" => 'staging')
      @resource.deploy_to("/my/app")
      mock_execution.should_receive(:user).with("notCoolMan")
      mock_execution.should_receive(:group).with("Ggroup")
      mock_execution.should_receive(:cwd){|*args|
        if args.empty?
          nil
        else
          args.size.should == 1
          args.first.should == @provider.release_path
        end
      }.twice
      mock_execution.should_receive(:environment){ |*args|
        if args.empty?
          nil
        else
          args.size.should == 1
          args.first.should == {"APP_ENV" => "staging"}
        end
      }.twice
      @provider.run("iGoToHell4this")
    end

    it "defines run as a forwarder to execute, setting cwd and environment but not override" do
      mock_execution = mock("Resource::Execute")
      @provider.should_receive(:execute).with("iGoToHell4this").and_return(mock_execution)
      @resource.user("notCoolMan")
      mock_execution.should_receive(:user).with("notCoolMan")
      mock_execution.should_receive(:cwd).with(no_args()).and_return("/some/value")
      mock_execution.should_receive(:environment).with(no_args()).and_return({})
      @provider.run("iGoToHell4this")
    end

    it "converts sudo and run to exec resources in hooks" do
      runner = mock("tehRunner")
      Chef::Runner.stub!(:new).and_return(runner)

      snitch = nil
      @resource.user("tehCat")

      callback_code = Proc.new do
        snitch = 42
        temp_collection = self.resource_collection
        run("tehMice")
        snitch = temp_collection.lookup("execute[tehMice]")
      end

      runner.should_receive(:converge)
      @provider.callback(:phony, callback_code)
      snitch.should be_an_instance_of(Chef::Resource::Execute)
      snitch.user.should == "tehCat"
    end
  end

  describe "installing gems from a gems.yml" do

    before do
      ::File.stub!(:exist?).with("#{@expected_release_dir}/gems.yml").and_return(true)
      @gem_list = [{:name=>"eventmachine", :version=>"0.12.9"}]
    end

    it "reads a gems.yml file, creating gem providers for each with action :upgrade" do
      IO.should_receive(:read).with("#{@expected_release_dir}/gems.yml").and_return("cookie")
      YAML.should_receive(:load).with("cookie").and_return(@gem_list)

      gems = @provider.send(:gem_packages)

      gems.map { |g| g.action }.should == [[:install]]
      gems.map { |g| g.name }.should == %w{eventmachine}
      gems.map { |g| g.version }.should == %w{0.12.9}
    end

    it "takes a list of gem providers converges them" do
      IO.stub!(:read)
      YAML.stub!(:load).and_return(@gem_list)
      expected_gem_resources = @provider.send(:gem_packages).map { |r| [r.name, r.version] }
      gem_runner = @provider.send(:gem_resource_collection_runner)
      # no one has heard of defining == to be meaningful so I have use this monstrosity
      actual = gem_runner.run_context.resource_collection.all_resources.map { |r| [r.name, r.version] }
      actual.should == expected_gem_resources
    end

  end

end
