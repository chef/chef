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
    @provider = Chef::Provider::Deploy.new(@node, @resource)
  end
  
  it "supports :deploy and :rollback actions" do
    @provider.should respond_to(:action_deploy)
    @provider.should respond_to(:action_rollback)
  end
  
  it "updates and copies the repo, then does a migrate, symlink, restart, restart, cleanup on deploy" do
    @provider.should_receive(:enforce_ownership).twice
    @provider.should_receive(:update_cached_repo)
    @provider.should_receive(:copy_cached_repo)
    @provider.should_receive(:callback).with(:before_migrate)
    @provider.should_receive(:migrate)
    @provider.should_receive(:callback).with(:before_symlink)
    @provider.should_receive(:symlink)
    @provider.should_receive(:callback).with(:before_restart)
    @provider.should_receive(:restart)
    @provider.should_receive(:callback).with(:after_restart)
    @provider.should_receive(:cleanup!)
    @provider.action_deploy
  end
  
  it "sets the release path to the penultimate release, symlinks, and rm's the last release on rollback" do
    all_releases = ["/my/deploy/dir/releases/20040815162342", "/my/deploy/dir/releases/20040700000000",
                    "/my/deploy/dir/releases/20040600000000", "/my/deploy/dir/releases/20040500000000"].sort!
    Dir.stub!(:glob).with("/my/deploy/dir/releases/*").and_return(all_releases)
    @provider.should_receive(:symlink)
    FileUtils.should_receive(:rm_rf).with("/my/deploy/dir/releases/20040815162342")
    @provider.action_rollback
    @provider.release_path.should eql("/my/deploy/dir/releases/20040700000000")
  end
  
  it "raises a runtime error when there's no release to rollback to" do
    all_releases = []
    Dir.stub!(:glob).with("/my/deploy/dir/releases/*").and_return(all_releases)
    lambda {@provider.action_rollback}.should raise_error(RuntimeError)
  end
  
  it "execs callbacks from the deploy/ dir if the file exists" do
    foo_callback = @expected_release_dir + "/deploy/foo.rb"
    ::File.should_receive(:exist?).with(foo_callback).and_return(true)
    ::Dir.should_receive(:chdir).with(@expected_release_dir).and_yield
    @provider.should_receive(:from_file).with(foo_callback)
    @provider.callback(:foo)
  end
  
  it "skips a callback if the file doesn't exist" do
    barbaz_callback = @expected_release_dir + "/deploy/barbaz.rb"
    ::File.should_receive(:exist?).with(barbaz_callback).and_return(false)
    @provider.should_not_receive(:from_file)
    @provider.callback(:barbaz)
  end
  
  it "gets a SCM provider as specified by its resource" do
    @provider.scm_provider.should be_an_instance_of(Chef::Provider::Git)
    @provider.scm_provider.new_resource.destination.should eql("/my/deploy/dir/shared/cached-copy/")
  end
  
  it "syncs the cached copy of the repo" do
    @provider.scm_provider.should_receive(:action_sync)
    @provider.update_cached_repo
  end
  
  it "makes a copy of the cached repo in releases dir" do
    FileUtils.should_receive(:mkdir_p).with("/my/deploy/dir/releases")
    FileUtils.should_receive(:cp_r).with( "/my/deploy/dir/shared/cached-copy/", 
                                          @expected_release_dir, 
                                          :preserve => true)
    @provider.copy_cached_repo
  end
  
  
  it "chowns the whole release dir to user and group specified in the resource" do
    @resource.user "foo"
    @resource.group "bar"
    FileUtils.should_receive(:chown_R).with("foo", "bar", "/my/deploy/dir")
    @provider.enforce_ownership
  end
  
  it "skips the migration when resource.migrate => false" do
    @resource.migrate false
    @provider.should_not_receive :run_command
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
    @provider.should_receive(:run_command).with(:command => "restartcmd", :cwd => "/my/deploy/dir/current")
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
  
  it "puts resource.to_hash in @configuration for backwards compat with capistano-esque deploy hooks" do
    @provider.instance_variable_get(:@configuration).should == @resource.to_hash
  end
  
  it "sets @configuration[:environment] to the value of RAILS_ENV for backwards compat reasons" do
    resource = Chef::Resource::Deploy.new("/my/deploy/dir")
    resource.environment "production" 
    provider = Chef::Provider::Deploy.new(@node, resource)
    provider.instance_variable_get(:@configuration)[:environment].should eql("production")
  end
  
  it "shouldn't give a no method error on migrate if the environment is nil" do
    @provider.stub!(:enforce_ownership)
    @provider.stub!(:link_shared_db_config_to_current_release)
    @provider.stub!(:run_command)
    @provider.migrate
  end
  
end
